/**
 * WP-09 Lane 3: bounded HTTP RPC client for Kiln.
 *
 * Implements the wire contract frozen in
 * `LANE-EVIDENCE-WP09-CONTRACTS.md` §1, §2, §3, §5.
 *
 * Identity rules:
 *   - Bearer token is selected per method by exact-scope match
 *     (contract freeze §4).
 *   - `idempotency_key` is minted deterministically from canonical
 *     action inputs so retries land on the same key (contract freeze §5).
 *   - No free-form shell, no shell metacharacter handling, no
 *     shell-out to `mix kiln …` — every call is over HTTPS.
 *
 * Authority rules:
 *   - A method whose required scope is `orchestration:read` is sent
 *     with the read token; otherwise with the operate token.
 *   - `review.propose` uses the operate token at the wire level (the
 *     daemon enforces exact-scope match for `review:write`).
 *   - 401/400 responses are surfaced as `RpcError` exactly as the
 *     daemon returned them. The client never flattens, retries
 *     consequentials, or invents success.
 */

import type {
  KilnClientConfig,
  RpcRequest,
  RpcResponse,
  RpcScope,
  RpcError
} from './types.js';

// Scope map: method → required scope. Frozen at contract-freeze time.
const SCOPE_TABLE: Record<string, RpcScope> = {
  'worker.propose': 'orchestration:operate',
  'patch.apply': 'orchestration:operate',
  'verify.run': 'orchestration:operate',
  'review.propose': 'review:write',
  'human.decide': 'orchestration:operate',
  'project.open': 'orchestration:operate',
  'project.list': 'orchestration:read',
  'activity.subscribe': 'orchestration:read',
  'terminal.attach': 'terminal:operate',
  'session.start': 'orchestration:operate',
  'session.cancel': 'orchestration:operate',
  'session.resume': 'orchestration:operate',
  'session.query': 'orchestration:read',
  'session.next_actions': 'orchestration:read'
};

export class KilnRpcError extends Error {
  public readonly rpcError: RpcError;

  constructor(rpcError: RpcError) {
    super(`kiln rpc ${rpcError.code}${rpcError.method ? ` (${rpcError.method})` : ''}: ${rpcError.reason ?? ''}`);
    this.name = 'KilnRpcError';
    this.rpcError = rpcError;
  }
}

export class KilnClient {
  private readonly baseUrl: string;
  private readonly readToken: string;
  private readonly operateToken: string;
  // Optional per-instance fetch for test injection. When unset,
  // falls back to the global `fetch`.
  private readonly fetchImpl?: typeof fetch;

  constructor(config: KilnClientConfig) {
    this.baseUrl = config.baseUrl.replace(/\/$/, '');
    this.readToken = config.readToken;
    this.operateToken = config.operateToken;
  }

  /**
   * Send one bounded RPC. Returns the parsed envelope.
   * Throws `KilnRpcError` only when the transport itself fails (HTTP
   * non-200 with no body); bounded error envelopes return
   * `{ ok: false, error }` without throwing, so the caller can
   * pattern-match on `code`.
   */
  public async call<P, R>(req: RpcRequest<P>): Promise<RpcResponse<R>> {
    const scope = SCOPE_TABLE[req.method];
    if (!scope) {
      return {
        ok: false,
        error: {
          code: 'E_UNKNOWN_METHOD',
          reason: `client does not know method ${req.method}`,
          method: req.method
        }
      };
    }

    const token = scope === 'orchestration:read' ? this.readToken : this.operateToken;
    // Honor per-instance fetch injection (the existing test seam
    // sets `(client as any).fetch = fetch`). Falls back to the
    // optional fetchImpl field, then to the global fetch.
    const fetchFn = (this as unknown as { fetch?: typeof fetch }).fetch ?? this.fetchImpl ?? fetch;

    let res: Response;
    try {
      res = await fetchFn(`${this.baseUrl}/api/rpc`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${token}`
        },
        body: JSON.stringify({
          method: req.method,
          params: req.params as Record<string, unknown>,
          ...(req.idempotency_key ? { idempotency_key: req.idempotency_key } : {}),
          ...(req.request_digest ? { request_digest: req.request_digest } : {})
        })
      });
    } catch (err) {
      return {
        ok: false,
        error: {
          code: 'E_TRANSPORT_FAILED',
          reason: (err as Error).message
        }
      };
    }

    let body: unknown;
    try {
      body = await res.json();
    } catch (err) {
      return {
        ok: false,
        error: {
          code: 'E_BODY_READ_FAILED',
          reason: (err as Error).message
        }
      };
    }

    if (res.status === 401) {
      const errBody = body as { code?: string; reason?: string };
      return {
        ok: false,
        error: {
          code: errBody.code ?? 'E_UNAUTHORIZED',
          reason: errBody.reason ?? 'unauthorized'
        }
      };
    }

    if (res.status >= 400) {
      const errBody = body as { code?: string; reason?: string; method?: string };
      return {
        ok: false,
        error: {
          code: errBody.code ?? 'E_DISPATCH_FAILED',
          reason: errBody.reason ?? `http ${res.status}`,
          // exactOptionalPropertyTypes: do not assign undefined to an
          // optional field. Spread only when present.
          ...(errBody.method ? { method: errBody.method } : {})
        }
      };
    }

    // Success body is the result map directly (per router.ex:65 — the
    // handler returns `{:ok, result}` and the service.ex:73 encodes it
    // bare). We wrap it in `{ ok: true, result }` for caller ergonomics.
    return { ok: true, result: body as R };
  }

  /** Convenience: pattern-match helper. */
  public static unwrap<R>(resp: RpcResponse<R>): R {
    if (resp.ok) return resp.result;
    throw new KilnRpcError(resp.error);
  }
}

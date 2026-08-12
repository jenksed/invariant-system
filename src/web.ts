/**
 * Minimal local web surface.
 *
 * Serves the static files under /web/ and exposes one POST endpoint
 * /run that runs the same core pipeline the CLI uses. The page and the
 * server response always carry the `simulated` label.
 */
import http from 'node:http';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import {
  findGoalByTitle,
  compileWorkEnvelope,
  resolveCapability,
  invokeFakeKiln,
  buildResultView,
  workspacePaths,
  snapshotRepo
} from './index';
import { runRepositoryRecon } from './packs/repository-recon/run';

export interface WebOptions {
  port: number;
  defaultRepository: string;
  packsDir: string;
}

const WEB_ROOT = path.resolve(__dirname, '..', 'web');
const TYPES = new Map<string, string>([
  ['.html', 'text/html; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.js', 'application/javascript; charset=utf-8']
]);

function jsonResponse(res: http.ServerResponse, code: number, body: unknown): void {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

async function serveStatic(reqPath: string, res: http.ServerResponse): Promise<void> {
  const safe = reqPath === '/' ? '/index.html' : reqPath;
  const full = path.join(WEB_ROOT, safe);
  if (!full.startsWith(WEB_ROOT)) {
    res.writeHead(403);
    res.end('forbidden');
    return;
  }
  try {
    const buf = await fs.readFile(full);
    const ext = path.extname(full).toLowerCase();
    res.writeHead(200, { 'Content-Type': TYPES.get(ext) ?? 'application/octet-stream' });
    res.end(buf);
  } catch {
    res.writeHead(404);
    res.end('not found');
  }
}

async function readJsonBody(req: http.IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let buf = '';
    req.setEncoding('utf8');
    req.on('data', (chunk) => (buf += chunk));
    req.on('end', () => {
      if (!buf) return resolve({});
      try {
        resolve(JSON.parse(buf));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

export async function startWeb(opts: WebOptions): Promise<void> {
  const server = http.createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? '/', 'http://localhost');
      if (req.method === 'GET' && (url.pathname === '/' || url.pathname.startsWith('/static'))) {
        const rel = url.pathname.replace(/^\/static/, '');
        await serveStatic(rel, res);
        return;
      }
      if (req.method === 'POST' && url.pathname === '/run') {
        const body = (await readJsonBody(req)) as {
          goal?: string;
          repository?: string;
        };
        const goalTitle = body.goal ?? 'Understand this repository';
        const repository = body.repository ?? opts.defaultRepository;
        const goal = findGoalByTitle(goalTitle);
        if (!goal) {
          jsonResponse(res, 400, { error: `unknown goal: ${goalTitle}` });
          return;
        }
        const ws = workspacePaths(repository);
        const packRoot = path.join(ws.packs, 'repository-recon');
        try {
          await fs.stat(packRoot);
        } catch {
          jsonResponse(res, 409, {
            error: `pack repository-recon not installed at ${repository}; run 'loadout install repository-recon' first.`
          });
          return;
        }
        const cap = await resolveCapability(packRoot);
        const recon = await runRepositoryRecon(repository);
        const snap = await snapshotRepo(repository);
        const envelope = compileWorkEnvelope({
          goal,
          capability: cap,
          projectState: {
            repository,
            baseCommit: snap.input.headCommit,
            workspaceStateDigest: snap.digest
          },
          createdAt: new Date().toISOString()
        });
        const result = invokeFakeKiln(envelope);
        const view = buildResultView(result);
        jsonResponse(res, 200, { view, reconNotes: recon.notes, simulated: true });
        return;
      }
      res.writeHead(404);
      res.end('not found');
    } catch (e) {
      jsonResponse(res, 500, { error: (e as Error).message });
    }
  });

  await new Promise<void>((resolve) => server.listen(opts.port, '127.0.0.1', resolve));
  // eslint-disable-next-line no-console
  console.log(`loadout web (SIMULATED) listening on http://127.0.0.1:${opts.port}`);
}

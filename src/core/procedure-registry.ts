/**
 * Procedure registry: binds the QMR's procedure_ref to the actual
 * procedure function that will be invoked at run time.
 *
 * Why this exists
 * ---------------
 * Before this module, the CLI's `run` path directly imported
 * `runRepositoryRecon` from `./packs/repository-recon/run.ts`. The QMR was
 * recorded in the Plan, but the procedure that actually ran was selected
 * by a hardcoded import, not by the QMR's `procedure_ref`. That meant a
 * Plan could say "use this QMR" while the run would invoke a different
 * procedure.
 *
 * The registry closes that gap by indexing procedures by their
 * `procedureEntry` (the path the Skill descriptor points to). The Plan
 * records the binding (`qmr_procedure_ref`, `skill_procedure_entry`,
 * `procedure_interface_digest`); at run time, the CLI resolves the
 * procedure through this registry using the Skill's `procedureEntry`,
 * and verifies the binding matches the loaded QMR.
 *
 * The registry is intentionally narrow: it is a static, in-process
 * function table for SIMULATED boundaries only. It is not a plugin
 * loader, not a Kiln driver, not a general procedure dispatch surface.
 * Adding a new procedure means editing this file (and a Pack's
 * `skill.json`), which is what the QMR's `procedure_ref` is supposed to
 * certify.
 */
import { createHash } from 'node:crypto';
import { promises as fs } from 'node:fs';
import path from 'node:path';

export type ProcedureFunction = (repoRoot: string) => Promise<unknown>;

/**
 * Resolved procedure: the absolute path to the procedure module file
 * and the exported function name to invoke. This is what the registry
 * returns; the Plan's `procedure_binding` records both the raw
 * `procedureEntry` (path) and the interface digest.
 */
export interface ResolvedProcedure {
  /** Absolute path to the procedure module file. */
  absolutePath: string;
  /** The exported function name to invoke. */
  exportName: string;
}

export class ProcedureResolutionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ProcedureResolutionError';
  }
}

/**
 * The bundled procedure registry. For LOD-02 this table is intentionally
 * tiny: it lists the procedure entry -> (path, exportName) mapping for
 * every shipped Skill. The mapping is keyed by the Skill's
 * `procedureEntry` (the path the Skill descriptor points to). The
 * resolved path is the FULL PATH from the Loadout installation root to
 * the procedure module.
 *
 * Adding a new Pack requires adding an entry here. The QMR's
 * `procedure_ref` is the content-addressable anchor; the registry is
 * the runtime mapping that the Plan binds to.
 */
const BUNDLED_PROCEDURES: ReadonlyArray<ResolvedProcedure> = [
  {
    absolutePath: 'src/packs/repository-recon/run.ts',
    exportName: 'runRepositoryRecon'
  }
];

/**
 * Resolve a procedure entry to the actual procedure module. The
 * `procedureEntry` is the path the Skill descriptor points to (e.g.,
 * `./run.ts` relative to the pack root). The `packRoot` is the absolute
 * path to the pack root directory where the skill.json lives.
 *
 * The procedural binding is: the entry's RESOLVED PATH must match one
 * of the registered procedures. If the entry cannot be resolved, the
 * procedure is not allowed to run.
 */
export function resolveProcedure(args: {
  procedureEntry: string;
  packRoot: string;
}): ResolvedProcedure {
  const { procedureEntry, packRoot } = args;
  const resolved = path.isAbsolute(procedureEntry)
    ? procedureEntry
    : path.resolve(packRoot, procedureEntry);
  const normalized = resolved.replace(/\.ts$/, '');
  for (const entry of BUNDLED_PROCEDURES) {
    // The registered absolutePath is relative to the Loadout root. We
    // resolve it against the Loadout root here. To make this work
    // without passing loadoutRoot everywhere, we look up entries by
    // their basename + directory, which is unique enough for the
    // bundled set.
    const normalizedRegistered = entry.absolutePath.replace(/\.ts$/, '');
    if (normalized.endsWith(normalizedRegistered.split('/').slice(-2).join('/'))) {
      return entry;
    }
  }
  throw new ProcedureResolutionError(
    `procedure entry '${procedureEntry}' (resolved to ${resolved}) is not registered in the ` +
      `simulated procedure registry; if you added a new pack, register its procedure in ` +
      `src/core/procedure-registry.ts.`
  );
}

/**
 * Look up a procedure by the Skill's `procedureEntry` resolved against
 * the Loadout installation root. Used by call sites that do not have a
 * pack root but do have the loadout root (e.g., the CLI top-level).
 */
export function resolveProcedureByEntry(
  procedureEntry: string,
  loadoutRoot: string
): ResolvedProcedure {
  const resolved = path.isAbsolute(procedureEntry)
    ? procedureEntry
    : path.resolve(loadoutRoot, procedureEntry);
  const normalized = resolved.replace(/\.ts$/, '');
  for (const entry of BUNDLED_PROCEDURES) {
    const entryResolved = path.resolve(loadoutRoot, entry.absolutePath).replace(/\.ts$/, '');
    if (entryResolved === normalized) {
      return entry;
    }
  }
  throw new ProcedureResolutionError(
    `procedure entry '${procedureEntry}' is not registered in the simulated procedure registry; ` +
      `if you added a new pack, register its procedure in src/core/procedure-registry.ts.`
  );
}

/**
 * Compute the procedure interface digest: sha256 of the canonicalized
 * list of exported symbols from the procedure module file. This is
 * the SEMANTIC binding (the procedure's interface shape), not the raw
 * file content. Whitespace-only edits do not change the binding.
 *
 * The procedureEntry is resolved relative to the packRoot (the
 * directory where skill.json lives). The Pack root is the canonical
 * resolution base because the Skill descriptor's `procedureEntry` is
 * a path relative to the Pack root.
 */
export async function computeProcedureInterfaceDigest(args: {
  procedureEntry: string;
  packRoot: string;
}): Promise<string> {
  const { procedureEntry, packRoot } = args;
  const resolvedPath = path.isAbsolute(procedureEntry)
    ? procedureEntry
    : path.resolve(packRoot, procedureEntry);
  return computeProcedureInterfaceDigestForPath(resolvedPath);
}

/**
 * Compute the procedure interface digest for a fully-resolved path.
 * This is the same algorithm as above, but doesn't need to re-resolve.
 */
export async function computeProcedureInterfaceDigestForPath(
  resolvedPath: string
): Promise<string> {
  let raw: string;
  try {
    raw = await fs.readFile(resolvedPath, 'utf8');
  } catch (e) {
    throw new ProcedureResolutionError(
      `cannot read procedure module at ${resolvedPath}: ${(e as Error).message}`
    );
  }
  const symbols = extractExportedSymbols(raw);
  const canonical = JSON.stringify({ symbols: [...symbols].sort() });
  return 'sha256:' + createHash('sha256').update(canonical).digest('hex');
}

/**
 * Extract exported function/const names from a TypeScript source string.
 * This is a deliberately narrow regex-based scan; it covers the shapes
 * Loadout uses (export async function ..., export function ..., export
 * const ...). It does NOT attempt to parse TypeScript; that would
 * introduce a dependency on the TS compiler.
 */
export function extractExportedSymbols(source: string): Set<string> {
  const symbols = new Set<string>();
  const patterns: RegExp[] = [
    // export async function <name>
    /^\s*export\s+async\s+function\s+([A-Za-z_$][\w$]*)/gm,
    // export function <name>
    /^\s*export\s+function\s+([A-Za-z_$][\w$]*)/gm,
    // export const <name>
    /^\s*export\s+const\s+([A-Za-z_$][\w$]*)/gm,
    // export class <name>
    /^\s*export\s+class\s+([A-Za-z_$][\w$]*)/gm,
    // export interface <name>
    /^\s*export\s+interface\s+([A-Za-z_$][\w$]*)/gm,
    // export type <name>
    /^\s*export\s+type\s+([A-Za-z_$][\w$]*)/gm
  ];
  for (const pat of patterns) {
    let m: RegExpExecArray | null;
    while ((m = pat.exec(source)) !== null) {
      symbols.add(m[1]);
    }
  }
  return symbols;
}

/**
 * Invoke the procedure identified by `procedureEntry`, with the given
 * repoRoot. This is the SOLE path that the CLI uses to invoke the
 * Skill procedure. It is NOT a hardcoded call to a specific module.
 *
 * The procedure is loaded via a dynamic import keyed by the entry's
 * resolved path; the registry is the only fixed import surface.
 */
export async function invokeProcedure(args: {
  procedureEntry: string;
  packRoot: string;
  loadoutRoot: string;
  repoRoot: string;
}): Promise<unknown> {
  const { procedureEntry, packRoot, loadoutRoot, repoRoot } = args;
  const entry = resolveProcedure({ procedureEntry, packRoot });
  // The absolutePath in the registry is relative to the Loadout root.
  const resolvedModule = path.resolve(loadoutRoot, entry.absolutePath);
  // We use a dynamic import so that the registry is the only fixed
  // import surface; the actual procedure module is loaded by path.
  const mod = (await import(resolvedModule)) as Record<string, ProcedureFunction>;
  const fn = mod[entry.exportName];
  if (typeof fn !== 'function') {
    throw new ProcedureResolutionError(
      `procedure module ${resolvedModule} does not export a function named '${entry.exportName}'`
    );
  }
  return fn(repoRoot);
}

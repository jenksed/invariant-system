/**
 * Temper operator command executor.
 *
 * Syntax/availability come from commands.ts. This module binds those commands
 * to real Workbench/Kiln seams. It owns no workflow truth: consequential
 * results are followed by canonical resync, and read-only explanations quote
 * only the latest projection or Kiln-returned next actions.
 */

import {
  commandAvailability,
  commandSpecs,
  formatCommandHelp,
  parseCommand,
  type CommandId
} from './commands.js';
import type { OperatorController, OperatorResult, SessionGraph } from './operator.js';
import type { WorkbenchProjection } from './projection.js';

export interface CommandExecutionResult {
  ok: boolean;
  command: CommandId | 'parse';
  lines: string[];
}

export interface CommandExecutorDeps {
  getProjection: () => WorkbenchProjection;
  operator: Pick<OperatorController, 'nextActions' | 'cancel' | 'resume' | 'graph' | 'doctor'>;
  actorId: string;
  startSession: (objective: string) => Promise<void>;
  resync: () => Promise<void>;
  decide: (
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION'
  ) => Promise<{ ok: boolean; errorCode?: string; errorReason?: string }>;
  reconnect: () => Promise<{ ok: boolean; error?: string }>;
  openDiff: () => void;
  quit: () => void;
  /** Provider reporting is inspection-only until a real selection contract is wired. */
  providerReport?: () => Promise<string[]> | string[];
}

export class CommandExecutor {
  constructor(private readonly deps: CommandExecutorDeps) {}

  async execute(line: string): Promise<CommandExecutionResult> {
    const parsed = parseCommand(line);
    if ('error' in parsed) {
      return { ok: false, command: 'parse', lines: [parsed.error] };
    }

    const projection = this.deps.getProjection();
    const availability = commandAvailability(parsed.spec, projection);
    if (!availability.available) {
      return {
        ok: false,
        command: parsed.spec.id,
        lines: [`UNAVAILABLE: ${availability.reason ?? 'command precondition not satisfied'}`]
      };
    }

    switch (parsed.spec.id) {
      case 'help':
        return ok('help', formatCommandHelp(projection).split('\n'));
      case 'status':
        return ok('status', statusLines(projection));
      case 'project':
        return ok('project', projectLines(projection));
      case 'session':
        return ok('session', sessionLines(projection));
      case 'new':
        return this.startSession(parsed.argv);
      case 'resume':
        return this.transition('resume', projection);
      case 'cancel':
        return this.transition('cancel', projection);
      case 'next':
        return this.next(projection);
      case 'diff':
        this.deps.openDiff();
        return ok('diff', ['Opened bounded repository diff.']);
      case 'evidence':
        return ok('evidence', evidenceLines(projection));
      case 'why':
        return this.why(projection);
      case 'graph':
        return this.graph(projection);
      case 'accept':
        return this.decide('accept', 'ACCEPT');
      case 'reject':
        return this.decide('reject', 'REJECT');
      case 'revise':
        return this.decide('revise', 'REQUEST_REVISION');
      case 'reconnect':
        return this.reconnect();
      case 'doctor':
        return this.doctor(projection);
      case 'capabilities':
        return ok('capabilities', capabilityLines(projection));
      case 'providers':
        return this.providers();
      case 'quit':
        this.deps.quit();
        return ok('quit', ['Temper shutdown requested.']);
    }
  }

  private async startSession(argv: string[]): Promise<CommandExecutionResult> {
    const objective = argv.join(' ').trim();
    if (!objective) {
      return fail('new', ['usage: /new <objective>']);
    }
    try {
      await this.deps.startSession(objective);
      return ok('new', ['Kiln accepted session.start.', `objective=${objective}`]);
    } catch (error) {
      return fail('new', [`session.start failed: ${message(error)}`]);
    }
  }

  private async transition(
    command: 'resume' | 'cancel',
    projection: WorkbenchProjection
  ): Promise<CommandExecutionResult> {
    const result =
      command === 'resume'
        ? await this.deps.operator.resume(projection, this.deps.actorId)
        : await this.deps.operator.cancel(projection, this.deps.actorId);
    if (!result.ok) return operatorFailure(command, result);
    await this.deps.resync();
    return ok(command, [
      `Kiln accepted session.${command}.`,
      `canonical_revision=${this.deps.getProjection().sessionQuery?.session_revision ?? 'unknown'}`
    ]);
  }

  private async next(projection: WorkbenchProjection): Promise<CommandExecutionResult> {
    const result = await this.deps.operator.nextActions(projection);
    if (!result.ok) return operatorFailure('next', result);
    const actions = result.result ?? [];
    return ok('next', actions.length > 0 ? ['Kiln next actions:', ...actions.map((item) => `- ${item}`)] : ['Kiln returned no next actions.']);
  }

  private async why(projection: WorkbenchProjection): Promise<CommandExecutionResult> {
    const result = await this.deps.operator.nextActions(projection);
    if (!result.ok) return operatorFailure('why', result);
    const sq = projection.sessionQuery;
    const lines = [
      `session=${projection.sessionId ?? 'none'}`,
      `run_state=${sq?.run_state ?? 'unknown'}`,
      `workflow_step=${sq?.workflow_step ?? 'unknown'}`,
      `verification=${sq?.verification_status ?? 'unknown'}`,
      `review=${sq?.review_status ?? 'unknown'}`,
      `human=${sq?.human_status ?? 'unknown'}`,
      'Kiln next actions:'
    ];
    const actions = result.result ?? [];
    lines.push(...(actions.length > 0 ? actions.map((item) => `- ${item}`) : ['- none']));
    lines.push('No additional causal claim is inferred by Temper.');
    return ok('why', lines);
  }

  private async graph(projection: WorkbenchProjection): Promise<CommandExecutionResult> {
    const result = await this.deps.operator.graph(projection);
    if (!result.ok) return operatorFailure('graph', result);
    return ok('graph', graphLines(result.result));
  }

  private async decide(
    command: 'accept' | 'reject' | 'revise',
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION'
  ): Promise<CommandExecutionResult> {
    const result = await this.deps.decide(decision);
    if (!result.ok) {
      return fail(command, [`${result.errorCode ?? 'E_DECISION_FAILED'} ${result.errorReason ?? ''}`.trim()]);
    }
    await this.deps.resync();
    return ok(command, [
      `Kiln accepted human.decide ${decision}.`,
      `canonical_revision=${this.deps.getProjection().sessionQuery?.session_revision ?? 'unknown'}`
    ]);
  }

  private async reconnect(): Promise<CommandExecutionResult> {
    const result = await this.deps.reconnect();
    if (!result.ok) return fail('reconnect', [`reconnect failed: ${result.error ?? 'unknown transport error'}`]);
    const projection = this.deps.getProjection();
    return ok('reconnect', [
      `transport=${projection.connection}`,
      `session=${projection.sessionId ?? 'none'}`,
      `canonical_revision=${projection.sessionQuery?.session_revision ?? 'unknown'}`
    ]);
  }

  private async doctor(projection: WorkbenchProjection): Promise<CommandExecutionResult> {
    const result = await this.deps.operator.doctor(projection);
    if (!result.ok) return operatorFailure('doctor', result);
    return ok('doctor', ['INVARIANT WORKBENCH DOCTOR', ...(result.result ?? [])]);
  }

  private async providers(): Promise<CommandExecutionResult> {
    if (!this.deps.providerReport) {
      return ok('providers', [
        'Provider selection is not exposed by the current Workbench contract.',
        'No provider/model change was made.'
      ]);
    }
    return ok('providers', await this.deps.providerReport());
  }
}

function ok(command: CommandId, lines: string[]): CommandExecutionResult {
  return { ok: true, command, lines };
}

function fail(command: CommandId, lines: string[]): CommandExecutionResult {
  return { ok: false, command, lines };
}

function operatorFailure(command: CommandId, result: OperatorResult<unknown>): CommandExecutionResult {
  return fail(command, [`${result.errorCode ?? 'E_OPERATOR_COMMAND'} ${result.errorReason ?? ''}`.trim()]);
}

function statusLines(p: WorkbenchProjection): string[] {
  const sq = p.sessionQuery;
  return [
    `transport=${p.connection}`,
    `project=${p.repository}`,
    `session=${p.sessionId ?? 'none'}`,
    `canonical_revision=${sq?.session_revision ?? p.canonicalSessionRevision ?? 'unknown'}`,
    `run_state=${sq?.run_state ?? 'unknown'}`,
    `verification=${sq?.verification_status ?? 'unknown'}`,
    `review=${sq?.review_status ?? 'unknown'}`,
    `human=${sq?.human_status ?? 'unknown'}`,
    `orphaned=${p.orphaned}`,
    ...(p.lastError ? [`last_error=${p.lastError}`] : [])
  ];
}

function projectLines(p: WorkbenchProjection): string[] {
  return [
    `repository=${p.repository}`,
    `kiln_home=${p.kilnHome}`,
    `orphaned=${p.orphaned}`,
    `unknowns=${p.unknowns.length}`
  ];
}

function sessionLines(p: WorkbenchProjection): string[] {
  const sq = p.sessionQuery;
  return [
    `session=${p.sessionId ?? 'none'}`,
    `task=${sq?.task_id ?? 'unknown'}`,
    `run=${sq?.root_run_id ?? 'unknown'}`,
    `objective=${sq?.objective ?? 'unknown'}`,
    `session_state=${sq?.session_state ?? 'unknown'}`,
    `task_state=${sq?.task_state ?? 'unknown'}`,
    `run_state=${sq?.run_state ?? 'unknown'}`,
    `revision=${sq?.session_revision ?? 'unknown'}`,
    `projection_digest=${sq?.projection_digest ?? 'unknown'}`
  ];
}

function evidenceLines(p: WorkbenchProjection): string[] {
  const sq = p.sessionQuery;
  const refs = sq?.references;
  const envelope = refs?.decision_envelope;
  const lines = [
    `journal_head=${sq?.journal_head_digest ?? 'unknown'}`,
    `projection_digest=${sq?.projection_digest ?? 'unknown'}`,
    `project_observation=${refs?.project_observation_id ?? 'unknown'}`
  ];
  if (!envelope) {
    lines.push('decision_envelope=none');
    return lines;
  }
  lines.push(
    `plan_ref=${formatRef(envelope.plan_ref)}`,
    `patch_ref=${formatRef(envelope.patch_ref)}`,
    `result_state_digest=${envelope.result_state_digest}`,
    `review_ref=${formatRef(envelope.review_ref)}`
  );
  return lines;
}

function graphLines(graph: SessionGraph | undefined): string[] {
  if (!graph) return ['Kiln returned no graph payload.'];
  const lines = [
    `schema=${graph.schema}`,
    `session=${graph.session_id}`,
    `revision=${graph.revision}`,
    `projection_digest=${graph.projection_digest}`,
    `source=${graph.source}`,
    `orphaned=${graph.orphaned}`,
    `nodes=${graph.nodes.length} edges=${graph.edges.length}`
  ];
  for (const node of graph.nodes) lines.push(`node ${node.kind} ${node.id}`);
  for (const edge of graph.edges) lines.push(`edge ${edge.kind} ${edge.from} -> ${edge.to}`);
  return lines;
}

function capabilityLines(p: WorkbenchProjection): string[] {
  const lines = ['COMMAND CAPABILITIES'];
  for (const spec of commandSpecs()) {
    const state = commandAvailability(spec, p);
    lines.push(
      `/${spec.name} authority=${spec.authority} ${state.available ? 'available' : `unavailable: ${state.reason ?? 'blocked'}`}`
    );
  }
  return lines;
}

function formatRef(ref: { id: string; digest: string } | null | undefined): string {
  return ref ? `${ref.id}@${ref.digest}` : 'none';
}

function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

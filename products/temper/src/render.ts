import type { Focus, SourceFact, WorkbenchModel } from './types.js';

export const FOCUSES: Focus[] = [
  'overview',
  'plan',
  'run',
  'authority',
  'evidence',
  'artifacts',
  'raw',
  'help',
  'loop'
];

export function renderWorkbench(model: WorkbenchModel, focus: Focus, width = 100): string {
  const safeWidth = Math.max(48, width);
  const body = panelLines(model, focus, safeWidth - 4);
  const header = ` TEMPER · ${model.repositoryName} · ${model.currentness.toUpperCase()} `;
  const footer = ` [p]lan [u]run [l]oop [a]uthority [e]vidence ar[t]ifacts [r]aw [?]help [esc]overview [q]uit `;
  const lines = [topBorder(header, safeWidth), ...body.map((line) => row(line, safeWidth))];

  while (lines.length < 20) lines.push(row('', safeWidth));
  lines.push(bottomBorder(footer, safeWidth));
  return lines.join('\n');
}

function panelLines(model: WorkbenchModel, focus: Focus, width: number): string[] {
  switch (focus) {
    case 'overview':
      return overview(model, width);
    case 'plan':
      return detail(
        'PLAN',
        model.plan ? JSON.stringify(model.plan, null, 2) : na('Plan', model),
        width,
        model.plan ? model.sources.plan : undefined
      );
    case 'run':
      return runPanel(model, width);
    case 'authority':
      return authorityPanel(model, width);
    case 'evidence':
      return evidencePanel(model, width);
    case 'artifacts':
      return artifactsPanel(model, width);
    case 'raw':
      return detail(
        'RAW RUN RESULT · exact RunResultEnvelope JSON',
        model.result ? JSON.stringify(model.result, null, 2) : na('Run Result', model),
        width,
        model.result ? model.sources.raw : undefined
      );
    case 'help':
      return helpPanel(model);
    case 'loop':
      return loopPanel(model, width);
  }
}

function overview(model: WorkbenchModel, width: number): string[] {
  const result = model.result;
  const plan = model.plan;
  const lines = [
    '',
    ' WORKBENCH / OVERVIEW',
    '',
    ...fieldLines('Repository', model.repository, width),
    ...fieldLines(
      'Repo currentness',
      `${model.currentness.toUpperCase()} (Temper-derived) — ${model.currentnessReason}`,
      width
    ),
    '',
    ...fieldLines('Goal', plan?.goal.title ?? na('Goal', model), width),
    ...fieldLines('Plan', plan?.plan_id ?? na('Plan', model), width),
    ...fieldLines('Kiln Run', result?.run_id ?? na('Run', model), width),
    ...fieldLines('Run state', result?.status ?? na('Run state', model), width),
    ...fieldLines('Authority', authoritySummary(model), width),
    ...fieldLines(
      'Evidence',
      result ? `${result.evidence.length} real reference(s)` : na('Evidence', model),
      width
    ),
    ...fieldLines(
      'Artifacts',
      result ? `${artifactRefs(model).length} real reference(s)` : na('Artifacts', model),
      width
    ),
    ...fieldLines('Unknowns', result ? String(result.unknowns.length) : na('Unknowns', model), width),
    ...fieldLines(
      'Acceptance',
      result
        ? `${result.acceptance_readiness.ready ? 'READY' : 'NOT READY'} — ${result.acceptance_readiness.reasons.join('; ') || 'no reasons supplied'}`
        : na('Acceptance readiness', model),
      width
    )
  ];
  if (model.errors.length) {
    lines.push(
      '',
      ' INPUT GAPS',
      ...model.errors.flatMap((error) => wrap(`   - ${error}`, width))
    );
  }
  return lines;
}

function runPanel(model: WorkbenchModel, width: number): string[] {
  const result = model.result;
  if (!result) return [' RUN', '', ` ${na('Run', model)}`];
  return [
    ' RUN',
    '',
    ...fieldLines('Run id', result.run_id, width),
    ...fieldLines('Work id', result.work_id, width),
    ...fieldLines('State', result.status, width),
    ...fieldLines('Input commit', result.input_state.base_commit, width),
    ...fieldLines('Final commit', result.final_state.commit, width),
    ...fieldLines(
      'Repo currentness',
      `${model.currentness} (Temper-derived) — ${model.currentnessReason}`,
      width
    ),
    ...fieldLines('Proof satisfied', result.proof_obligations.satisfied.join(', ') || '(none)', width),
    ...fieldLines('Proof unsatisfied', result.proof_obligations.unsatisfied.join(', ') || '(none)', width),
    ...fieldLines('Proof invalidated', result.proof_obligations.invalidated.join(', ') || '(none)', width),
    '',
    ...sourceLines(model.sources.run_id, width)
  ];
}

function authorityPanel(model: WorkbenchModel, width: number): string[] {
  const authority = model.result?.authority;
  if (!authority) return [' AUTHORITY', '', ` ${na('Authority', model)}`];
  const capabilities = [...new Set([...authority.requested, ...authority.granted, ...authority.denied])];
  return [
    ' AUTHORITY · Kiln-owned decision',
    '',
    ...(capabilities.length
      ? capabilities.map((capability) => {
          const decision = authority.granted.includes(capability)
            ? 'GRANTED'
            : authority.denied.includes(capability)
              ? 'DENIED'
              : 'REQUESTED / UNRESOLVED';
          return fieldLines(capability, decision, width);
        })
        .flat()
      : ['   (no authority requests recorded)']),
    '',
    ...sourceLines(model.sources.authority, width)
  ];
}

function evidencePanel(model: WorkbenchModel, width: number): string[] {
  const evidence = model.result?.evidence;
  if (!evidence) return [' EVIDENCE', '', ` ${na('Evidence', model)}`];
  return [
    ' EVIDENCE · Kiln-authored references',
    '',
    ...(evidence.length
      ? evidence.flatMap((item, index) => [
          ...fieldLines(`#${index + 1}`, item.id, width),
          ...fieldLines('kind', item.kind, width),
          ...fieldLines('state digest', item.state_digest, width),
          ...fieldLines(
            'freshness',
            'n/a — currentness projection is not present in Run Result Envelope v0',
            width
          ),
          ...fieldLines(
            'contradiction',
            'n/a — contradiction projection is not present in Run Result Envelope v0',
            width
          ),
          ''
        ])
      : ['   (no Evidence references recorded)']),
    ...sourceLines(model.sources.evidence, width)
  ];
}

function artifactsPanel(model: WorkbenchModel, width: number): string[] {
  const refs = artifactRefs(model);
  if (!model.result) return [' ARTIFACTS', '', ` ${na('Artifacts', model)}`];
  return [
    ' ARTIFACTS · references from Run effects',
    '',
    ...(refs.length
      ? refs.flatMap((effect, index) => [
          ...fieldLines(`#${index + 1}`, String(effect.artifact_id), width),
          ...fieldLines(
            'kind',
            typeof effect.kind === 'string' ? effect.kind : 'n/a — effect kind missing',
            width
          ),
          ''
        ])
      : ['   (no Artifact references recorded)']),
    ...sourceLines(model.sources.artifacts, width)
  ];
}

// M10 development-loop focus: project the M0 RunResultProjection in
// operator-readable form. Each stage carries the bounded truth status
// from the projection; missing stages render `n/a — <reason>` (never
// inferred). Source commands surface the owning Kiln CLI invocation
// that produced each artifact.
function loopPanel(model: WorkbenchModel, width: number): string[] {
  const proj = model.m0?.projection;
  const plan = model.plan;

  if (!proj) {
    const reason =
      model.m0?.projectionPath
        ? `projection at ${model.m0.projectionPath} was rejected (see errors); see raw focus for details`
        : 'no M0 RunResultProjection is available — run `mix kiln human-decide` to produce one';
    return [' M0 DEVELOPMENT LOOP', '', ` ${na('M0 projection', model)} — ${reason}`];
  }

  const lines: string[] = [
    ' M0 DEVELOPMENT LOOP',
    '',
    ...fieldLines(
      'Run status',
      proj.truth.run_status,
      width,
      `mix kiln human-decide` /* owning command for projection */
    ),
    ...fieldLines(
      'Verification',
      proj.truth.verification_status,
      width,
      `mix kiln verify-run`
    ),
    ...fieldLines(
      'Review',
      proj.truth.review_status === null || proj.truth.review_status === undefined
        ? na('Review', model)
        : proj.truth.review_status,
      width,
      `mix kiln review-propose`
    ),
    ...fieldLines(
      'Human decision',
      proj.truth.human_status,
      width,
      `mix kiln human-decide`
    ),
    '',
    ' PROVENANCE — every stage binds a canonical artifact ref',
    ...artifactRefLine('Plan', proj.plan_ref, width),
    ...artifactRefLine('Implementer', proj.implementer_assignment_ref, width),
    ...artifactRefLine('Reviewer', proj.reviewer_assignment_ref, width),
    ...artifactRefLine('Patch', proj.patch_ref, width),
    ...artifactRefLine('Patch decision', proj.patch_decision_ref, width),
    ...artifactRefLine('Verification', proj.verification_ref, width),
    ...artifactRefLine('Review', proj.review_ref, width, true),
    ...artifactRefLine('Human decision', proj.human_decision_ref, width, true),
    ...artifactRefLine('Run result', proj.run_result_ref, width)
  ];

  if (proj.truth.unknown_effects.length > 0) {
    lines.push('');
    lines.push(' UNKNOWN EFFECTS');
    for (const id of proj.truth.unknown_effects) {
      lines.push(`   - ${id}`);
    }
  }

  if (model.m0?.projectionPath) {
    lines.push('');
    lines.push(` Source: ${model.m0.projectionPath}`);
  }

  if (plan) {
    lines.push('');
    lines.push(
      ` Plan binding: ${plan.plan_id} (${plan.goal.title})`
    );
  }

  if (model.errors.length) {
    lines.push('');
    lines.push(' INPUT GAPS');
    for (const e of model.errors) {
      lines.push(`   - ${e}`);
    }
  }

  return lines;
}

function artifactRefLine(
  label: string,
  ref: { id: string; digest: string } | null,
  width: number,
  _optional = false
): string[] {
  if (ref === null) {
    return fieldLines(label, `n/a — ${label.toLowerCase()} (not yet recorded)`, width);
  }
  return fieldLines(label, `${ref.id} (${ref.digest.slice(0, 16)}…)`, width);
}

function helpPanel(model: WorkbenchModel): string[] {
  return [
    ' HELP',
    '',
    '   Tab / arrows   move to the next or previous focus',
    '   p              Plan JSON',
    '   u              Run facts',
    '   a              Authority decisions',
    '   e              Evidence references',
    '   t              Artifact references',
    '   r              Raw canonical Run Result JSON',
    '   Escape         return to Overview',
    '   q / Ctrl-C     exit',
    '',
    ' TRUTHFULNESS',
    '   Temper is read-only. Missing or incompatible input is rendered as n/a with a reason.',
    '   It does not derive Evidence freshness or contradiction when those projections are absent.',
    '',
    field('Run source', model.runRecordPath ?? 'n/a — no Run record discovered'),
    field('Plan source', model.planPath ?? 'n/a — no Plan discovered')
  ];
}

function detail(title: string, json: string, width: number, source?: SourceFact): string[] {
  const lines = [` ${title}`, ''];
  for (const line of json.split('\n')) lines.push(...wrap(line, width - 2).map((part) => ` ${part}`));
  if (source) lines.push('', ...sourceLines(source, width));
  return lines;
}

function authoritySummary(model: WorkbenchModel): string {
  const authority = model.result?.authority;
  if (!authority) return na('Authority', model);
  if (authority.denied.length) return `DENIED: ${authority.denied.join(', ')}`;
  if (authority.granted.length) return `GRANTED: ${authority.granted.join(', ')}`;
  return authority.requested.length ? `UNRESOLVED: ${authority.requested.join(', ')}` : '(none requested)';
}

function artifactRefs(model: WorkbenchModel): Array<Record<string, unknown>> {
  return (model.result?.effects ?? []).filter((effect) => typeof effect.artifact_id === 'string');
}

function na(subject: string, model: WorkbenchModel): string {
  const relevant = model.errors.find((error) => error.toLowerCase().includes(subject.toLowerCase()));
  return `n/a — ${relevant ?? `${subject} is not available from discovered inputs`}`;
}

function sourceLines(source: SourceFact | undefined, width: number): string[] {
  if (!source) return [' SOURCE', '   n/a — source input is unavailable'];
  return [
    ' SOURCE',
    ...wrap(`   file: ${source.sourcePath}`, width),
    ...wrap(`   command: ${source.command}`, width)
  ];
}

function field(label: string, value: string): string {
  return `   ${label.padEnd(18)} ${value}`;
}

function fieldLines(
  label: string,
  value: string,
  width: number,
  sourceHint?: string
): string[] {
  const prefix = `   ${label.padEnd(18)} `;
  const continuation = ' '.repeat(prefix.length);
  const available = Math.max(8, width - prefix.length);
  const baseLines = wrap(value, available).map(
    (part, index) => `${index === 0 ? prefix : continuation}${part}`
  );
  if (sourceHint) {
    const hintLines = wrap(`   source: ${sourceHint}`, width);
    return [...baseLines, ...hintLines];
  }
  return baseLines;
}

function topBorder(title: string, width: number): string {
  const clipped = title.slice(0, width - 2);
  return `┌${clipped}${'─'.repeat(Math.max(0, width - clipped.length - 2))}┐`;
}

function bottomBorder(content: string, width: number): string {
  const clipped = content.slice(0, width - 2);
  return `└${clipped}${'─'.repeat(Math.max(0, width - clipped.length - 2))}┘`;
}

function row(content: string, width: number): string {
  const clipped = content.slice(0, width - 4);
  return `│ ${clipped}${' '.repeat(Math.max(0, width - clipped.length - 4))} │`;
}

function wrap(value: string, width: number): string[] {
  if (value.length <= width) return [value];
  const chunks: string[] = [];
  for (let index = 0; index < value.length; index += width) chunks.push(value.slice(index, index + width));
  return chunks;
}

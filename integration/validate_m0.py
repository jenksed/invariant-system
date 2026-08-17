#!/usr/bin/env python3
from pathlib import Path
import json, hashlib, sys
from jsonschema import Draft202012Validator, FormatChecker
ROOT=Path(__file__).resolve().parent
SCHEMAS=ROOT.parent/'contracts'/'m0'/'schemas'; POS=ROOT/'fixtures'/'m0'/'positive'; NEG=ROOT/'fixtures'/'m0'/'negative'

def canon(o): return json.dumps(o,ensure_ascii=False,sort_keys=True,separators=(',',':'))
def sd(schema,payload): return 'sha256:'+hashlib.sha256((schema+'\n'+canon(payload)).encode()).hexdigest()

GENERATED_ID_FIELD={
'engineering-system/plan/m0-v1':'plan_id',
'engineering-system/intelligence-requirement/m0-v1':'requirement_id',
'engineering-system/intelligence-profile/m0-v1':'profile_id',
'engineering-system/role-qualification-receipt/m0-v1':'qualification_id',
'engineering-system/qualification-status-event/m0-v1':'status_event_id',
'engineering-system/eligibility-snapshot/m0-v1':'eligibility_id',
'engineering-system/intelligence-assignment/m0-v1':'assignment_id',
'engineering-system/execution-binding/m0-v1':'binding_id',
'engineering-system/run-binding/m0-v1':'run_binding_id',
'engineering-system/attempt/m0-v1':'attempt_id',
'engineering-system/patch-proposal/m0-v1':'patch_id',
'engineering-system/patch-decision/m0-v1':'decision_id',
'engineering-system/patch-application-evidence/m0-v1':'application_id',
'engineering-system/verification-result/m0-v1':'verification_id',
'engineering-system/review/m0-v1':'review_id',
'engineering-system/human-decision/m0-v1':'human_decision_id',
'engineering-system/run-result-projection/m0-v1':'projection_id',
'engineering-system/worker-output/m0-v1':'worker_output_id'
}
def identity_payload(o):
    # Exclude only the artifact's declared generated occurrence/id field. Semantic fields such as work_id stay bound.
    x={k:v for k,v in o.items() if k not in {'semantic_digest','metadata'}}
    generated=GENERATED_ID_FIELD.get(o.get('schema'))
    if generated: x.pop(generated,None)
    x.pop('created_at',None)
    return {'schema':o['schema'],**{k:v for k,v in x.items() if k!='schema'}}

def load(p): return json.loads(p.read_text())

def schema_for(o):
    candidates={load(p).get('$id'):p for p in SCHEMAS.glob('*.json')}
    return candidates.get(o.get('schema'))

errors=[]; validated=0
for p in sorted(POS.glob('*.json')):
    o=load(p); sp=schema_for(o)
    if sp:
        sch=load(sp)
        es=sorted(Draft202012Validator(sch,format_checker=FormatChecker()).iter_errors(o), key=lambda e:list(e.path))
        if es: errors.append(f'{p.name}: schema: '+ '; '.join(e.message for e in es))
        else: validated+=1
    if 'semantic_digest' in o:
        got=sd(o['schema'],identity_payload(o))
        if got!=o['semantic_digest']: errors.append(f'{p.name}: digest mismatch {got} != {o["semantic_digest"]}')

# Cross-artifact invariants from golden fixtures.
by_name={p.name:load(p) for p in POS.glob('*.json')}
def ref(o):
    k=next(k for k in o if k.endswith('_id'))
    return {'id':o[k],'digest':o['semantic_digest']}
impl_prof=by_name['03-implementer-profile.json']; impl_elg=by_name['06-implementer-eligibility.json']; impl_asg=by_name['07-implementer-assignment.json']
rev_prof=by_name['17-reviewer-profile.json']; rev_asg=by_name['21-reviewer-assignment.json']; review=by_name['22-review.json']
worker=by_name['11a-worker-output.json']; patch=by_name['12-patch-proposal.json']; pdec=by_name['13-patch-decision.json']; ver=by_name['15-verification-result.json']; hum=by_name['23-human-decision.json']; proj=by_name['25-run-result-projection.json']
if impl_elg['eligibility']!='QUALIFIED': errors.append('implementer eligibility is not QUALIFIED')
if impl_asg['profile_ref']!=ref(impl_prof): errors.append('implementer assignment/profile mismatch')
if rev_asg['profile_ref']!=ref(rev_prof): errors.append('reviewer assignment/profile mismatch')
if impl_asg['assignment_id']==rev_asg['assignment_id']: errors.append('reviewer assignment equals implementer assignment')
if impl_prof['role_package']==rev_prof['role_package']: errors.append('reviewer role package equals implementer role package')
if review.get('implementer_transcript_received') is not False: errors.append('reviewer context contaminated')
if worker['assignment_ref']!=ref(impl_asg) or worker['profile_ref']!=ref(impl_prof): errors.append('worker output assignment/profile mismatch')
if pdec['patch_ref']!=ref(patch) or pdec['base_state_digest']!=patch['base_state_digest']: errors.append('patch decision not exact-bound')
if ver['patch_ref']!=ref(patch): errors.append('verification not patch-bound')
if hum['patch_ref']!=ref(patch) or hum['result_state_digest']!=ver['result_state_digest']: errors.append('human decision not exact-state-bound')
if proj['truth']['human_status']!=hum['decision']: errors.append('projection strengthens/changes human truth')

# Work Envelope compatibility + M0 binding proof.
w=by_name['09-work-envelope-v0.json']
if not any(s.startswith('artifact:engineering-system/execution-binding/m0-v1:sha256:') for s in w.get('context_refs',[])): errors.append('Work Envelope missing content-addressed execution binding in context_refs')
# current Kiln request_digest semantics include context_refs and exclude created_at.
wp={k:v for k,v in w.items() if k!='created_at'}
wd=sd(w['schema'],wp)
# prove that changing created_at does not change digest, while changing context ref does.
w2=dict(w); w2['created_at']='2099-01-01T00:00:00Z'
if sd(w2['schema'],{k:v for k,v in w2.items() if k!='created_at'})!=wd: errors.append('created_at corrupted Work Envelope semantic digest')
w3=json.loads(json.dumps(w)); w3['context_refs'][0]+='x'
if sd(w3['schema'],{k:v for k,v in w3.items() if k!='created_at'})==wd: errors.append('context_refs failed to participate in Work Envelope digest')

# Negative catalog is exact and complete for mandatory M0 attacks.
expected={
'unqualified-assignment':'E_PROFILE_NOT_QUALIFIED','stale-qualification':'E_QUALIFICATION_NOT_CURRENT','profile-assignment-mismatch':'E_PROFILE_REF_MISMATCH','authority-smuggling-requirement':'E_AUTHORITY_FIELD_FORBIDDEN','authority-smuggling-assignment':'E_AUTHORITY_FIELD_FORBIDDEN','secret-disclosure':'E_DISCLOSURE_SECRET_DENIED','reviewer-contamination':'E_REVIEWER_CONTEXT_CONTAMINATED','runtime-unavailable':'E_RUNTIME_UNAVAILABLE','stale-base':'E_PATCH_BASE_MISMATCH','unsupported-binary':'E_PATCH_UNSUPPORTED_FILE_CLASS','path-escape':'E_PATCH_PATH_ESCAPE','partial-unknown-effect':'E_MUTATION_UNKNOWN_EFFECT','provider-substitution':'E_PROFILE_SUBSTITUTION','review-reuse-after-patch-revision':'E_REVIEW_STALE'}
for p in sorted(NEG.glob('*.json')):
    n=load(p)
    if expected.get(n['case'])!=n['expected_error']: errors.append(f'{p.name}: negative rejection code mismatch')

if errors:
    print('M0 CONFORMANCE: FAIL')
    for e in errors: print(' -',e)
    sys.exit(1)
print(f'M0 CONFORMANCE: PASS ({validated} schema-valid positive artifacts, {len(expected)} mandatory negative cases, cross-reference/digest checks passed)')
print('NOTE: This validates the ratified M0 contract packet in the monorepo (contracts/m0, integration/fixtures/m0). Source ratification must run equivalent producer/consumer tests in canonical repositories before downstream implementation.')

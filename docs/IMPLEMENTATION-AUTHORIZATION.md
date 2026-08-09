# Implementation Authorization

**Document type:** Current implementation-authorization authority
**Status:** Accepted
**Current result:** No P1-S02 ticket or slice is authorized

An accepted plan describes work. An authorization record permits one bounded implementation package to begin. Passing CI, a pull-request body, an available branch, generated code, or an implementation Claim does not substitute for either.

For a `work/p<phase>-s<slice>-t<ticket>-*` ticket branch or `work/p<phase>-s<slice>-*` slice branch, `scripts/agent-preflight` requires:

1. exactly one governing plan whose `Status` begins with `Accepted`;
2. one matching file under `docs/authorizations/`;
3. `state=authorized`;
4. the exact work ID;
5. the owner who issued authorization;
6. the exact 40-character base commit reviewed by the owner;
7. the SHA-256 of the accepted governing plan;
8. an RFC 3339 authorization time;
9. bounded scope text; and
10. the recorded base commit to be an ancestor of the implementation state.

Planning work under `work/p<phase>-w<work>-*` can create or amend proposed implementation plans without an implementation authorization record. Planning work cannot implement the proposed runtime package.

## Current authority result

- P1-S01 authorization is historical and consumed by its accepted integration at `db02198`.
- P1-S02 is planned and unauthorized.
- P1-S02-T01 has no authorization record.
- PR #48 is available candidate implementation produced before valid Repository authorization. It is not accepted, merge-authorized, or evidence that authorization occurred.
- The next legitimate action is owner adjudication of the corrected T01 plan and candidate diff after this governance repair integrates.

Authorization is effective only when the record and accepted plan are present in the implementation branch's Repository state. Revocation or supersession requires a governance change that updates or removes the record before further implementation proceeds.

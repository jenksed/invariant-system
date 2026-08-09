# Implementation Authorization

**Document type:** Current implementation-authorization authority
**Status:** Accepted
**Current result:** No P1-S02 ticket or slice is authorized

An accepted plan describes work. An authorization record permits one bounded implementation package to begin. Passing CI, a pull-request body, an available branch, generated code, or an implementation Claim does not substitute for either.

For a `work/p<phase>-s<slice>-t<ticket>-*` ticket branch or `work/p<phase>-s<slice>-*` slice branch, `scripts/agent-preflight` requires:

1. exactly one tracked governing plan whose `Status` begins with `Accepted`;
2. one matching tracked file under `docs/authorizations/`;
3. `state=authorized`;
4. the exact work ID;
5. the owner who issued authorization, exactly matching `docs/authorizations/TRUSTED-OWNERS` in trusted Repository authority;
6. the exact 40-character base commit reviewed by the owner;
7. the SHA-256 of the accepted governing plan;
8. an RFC 3339 authorization time;
9. bounded scope text; and
10. the record keys in the documented canonical order;
11. valid calendar, clock, and offset values in the RFC 3339 authorization time;
12. non-whitespace owner and scope values;
13. the exact plan and record blobs to be committed unchanged in the explicit implementation commit and to exist unchanged at `refs/remotes/origin/main`;
14. the trusted commit containing that exact pair to be an ancestor of the implementation state; and
15. the recorded base commit to be an ancestor of that trusted authority-source commit.

The canonical remote-tracking ref must be freshly fetched before an authority result is relied on. A normal named local checkout validates its own `HEAD`. Pull-request CI may continue compiling and testing GitHub's synthetic test-merge checkout, but it must set `KILN_IMPLEMENTATION_COMMIT` to the immutable `github.event.pull_request.head.sha`, fetch that exact commit and its required history, and validate authority against that actual implementation head. The supplied value must be an exact 40-character lowercase commit SHA and resolve to the same commit. The synthetic merge commit is never the implementation identity for plan blobs, authorization blobs, or authority-source ancestry.

CI separately fetches canonical `main` into `refs/remotes/origin/main`. An implementation branch cannot create, accept, or authorize its own plan or record: both files must first integrate through the owner-reviewed governance path on canonical `main`, then the actual implementation head must descend from the exact authority-source commit.

`KILN_BRANCH` exists for detached CI checkouts. In a named local checkout, it must exactly match the checked-out branch and cannot reclassify implementation work as planning work.

Planning work under `work/p<phase>-w<work>-*` can create or amend proposed implementation plans without an implementation authorization record. Planning work cannot implement the proposed runtime package.

## Current authority result

- P1-S01 authorization is historical and consumed by its accepted integration at `db02198`.
- P1-S02 is planned and unauthorized.
- P1-S02-T01 has no authorization record.
- PR #48 is available candidate implementation produced before valid Repository authorization. It is not accepted, merge-authorized, or evidence that authorization occurred.
- The next legitimate action is owner adjudication of the corrected T01 plan and candidate diff after this governance repair integrates.

Authorization is effective only while the exact record and accepted plan remain active at trusted canonical `main` and unchanged in the explicit implementation commit. Revocation or supersession requires a governance change that updates or removes the trusted record before further implementation proceeds.

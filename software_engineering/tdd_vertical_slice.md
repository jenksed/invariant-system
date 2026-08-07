# TDD by Behavioral Vertical Slice

Use when building a feature/fix test-first through a meaningful public seam.

## Agree the seam

A **seam** is the interface where behavior can be exercised and observed without coupling the test to internals.

Before writing tests, identify the intended seam(s). Prefer the highest stable interface that can express the behavior. Do not multiply seams just to make tests easy.

## Good-test rules

Tests should:

- describe externally meaningful behavior;
- survive internal refactors;
- use expected results from an independent source of truth;
- fail for the intended missing/broken behavior;
- avoid mocking internal collaboration unless the seam itself requires an external adapter.

Avoid tautological assertions and tests that inspect implementation state through side channels.

## Loop

For each vertical slice:

1. Write one test for one observable behavior.
2. Run it and capture the expected red result.
3. Add only enough implementation to satisfy that behavior.
4. Run targeted compile/type/static checks and the test until green.
5. Inspect what this slice taught you before choosing the next behavior.
6. Repeat.

Do not write the entire test suite ahead of the implementation; that locks in imagined structure instead of learning slice-by-slice.

## Refactoring

Refactor when the accumulated implementation reveals a better structure, but preserve the behavioral seam and rerun tests. Do not use “refactor” as permission for unrelated architecture work.

## Completion

Run targeted checks continuously and the repository's full required verification at the end. Completion requires the evidence defined by the repository, not merely a green local test.
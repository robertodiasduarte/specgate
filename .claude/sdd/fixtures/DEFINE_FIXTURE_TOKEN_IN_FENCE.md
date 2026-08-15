# DEFINE: FIXTURE_TOKEN_IN_FENCE

> Test fixture for the exit-code contract — the canonical form appears ONLY inside a code
> fence (simulating the instructional note in DEFINE_TEMPLATE). Not a real feature.
> Expected: `scripts/verify-gate.sh` → **exit 0** (fenced blocks are excluded from detection).

## Problem Statement

This spec is complete. The note below documents how to flag an ambiguity (documentation mention):

```
[NEEDS CLARIFICATION: <specific question>]
```

## Verify Gate

```yaml
verify_gate:
  kind: test
  cmd: "true"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

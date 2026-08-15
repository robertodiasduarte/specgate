# DEFINE: FIXTURE_CONTROL

> Test fixture for the exit-code contract — identical to FIXTURE_NEEDS_CLARIFICATION but
> **without** the marker. Not a real feature. Expected: `scripts/verify-gate.sh` → **exit 0**
> (proves the marker check does not produce a false positive on a clean spec).

## Problem Statement

Outbound notifications go through the delivery queue in the bulk class (120s between messages) and must respect the provider rate limit.

## Verify Gate

```yaml
verify_gate:
  kind: test
  cmd: "true"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

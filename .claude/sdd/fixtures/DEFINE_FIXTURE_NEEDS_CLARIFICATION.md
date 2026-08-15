# DEFINE: FIXTURE_NEEDS_CLARIFICATION

> Test fixture for the exit-code contract — ACTIVE marker outside a code fence. Not a real feature.
> Expected: `scripts/verify-gate.sh` → **exit 5**, reporting a pending clarification.
> The gate block below is deliberately VALID (`cmd: true`): without the marker check this
> file would exit 0, so the test only passes if the detection actually works.

## Problem Statement

Outbound notifications go through the delivery queue [NEEDS CLARIFICATION: which throttle class applies — bulk (120s between messages) or interactive (no delay)?] and must respect the provider rate limit.

## Verify Gate

```yaml
verify_gate:
  kind: test
  cmd: "true"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

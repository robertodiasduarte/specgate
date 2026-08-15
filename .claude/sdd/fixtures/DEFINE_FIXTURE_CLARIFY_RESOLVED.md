# DEFINE: FIXTURE_CLARIFY_RESOLVED

> Test fixture for the exit-code contract — a `## Clarifications` log with a RESOLVED question,
> written in the mention convention (no canonical form). Not a real feature.
> Expected: `scripts/verify-gate.sh` → **exit 0** (resolved history must not block).

## Problem Statement

Outbound notifications go through the delivery queue in the bulk class (120s between messages, decided during clarification).

## Clarifications

### Session 2026-01-15

- [x] (5-integrations) Which throttle class applies to the delivery queue? → bulk, 120s; integrated into Problem Statement

## Verify Gate

```yaml
verify_gate:
  kind: test
  cmd: "true"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

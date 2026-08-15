# Fragment — Verify Gate (taxonomy of executable gates)

> Reusable. Attached conceptually to every spec (the `## Verify Gate` block) and read by
> `/build`, `/release` and `scripts/verify-gate.sh`. This is the mechanism the whole
> framework is named after: **acceptance becomes a command, not prose.**

## Why it exists

In most spec-driven workflows, acceptance lives in prose (`Acceptance Tests`, `Success
Criteria`) that nobody executes deterministically. Without an executable gate, autonomy
becomes garbage at scale — "the loop runs, but against what does it stop?". The Verify Gate
is that stop condition: one `pass/fail` command any loop, human or agent, can run.

## The block (goes in the spec)

````markdown
## Verify Gate

> Executable acceptance gate (pass/fail). `/build` and `/release` run this — it is **blocking**.

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- checkout.test.ts"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```
````

Run it: `scripts/verify-gate.sh .claude/sdd/features/DEFINE_<FEATURE>.md`

## Fields

| Field | Required | Meaning |
|---|---|---|
| `kind` | always | gate category (table below) |
| `cmd` | except `manual-ux` | executable command; for `manual-ux` use `"N/A (manual-ux)"` |
| `pass_when` | always | objective criterion: `exit 0` (default) · `exit N` · `contains: TEXT` |
| `threshold` | `eval` only | numeric target embedded in the `cmd` (e.g. `recall >= 0.80`) — informational here |
| `manual_fallback` | `manual-ux` only | human checklist to walk through and sign in the build report |

> **No inline comments on value lines** of this machine-read block — the parser takes
> everything after the first `:`. Commentary goes outside the fence.

## Taxonomy (`kind`)

| kind | When | Typical `cmd` | `pass_when` |
|---|---|---|---|
| `test` | pure, testable logic | `npm test -- <file>` · `pytest tests/x -q` | `exit 0` |
| `smoke` | an endpoint answers as expected | `curl -sS -o /dev/null -w '%{http_code}' <url>` | `contains: 401` |
| `eval` | quality with a threshold | `scripts/eval/run.sh --threshold 0.80` | `exit 0` (threshold inside the cmd) |
| `typecheck` | types/compilation | `tsc --noEmit` · `mypy .` | `exit 0` |
| `manual-ux` | pure UX (mobile, aesthetics) | `N/A (manual-ux)` | **human** gate (`manual_fallback`) |

### Deriving `kind` from the test's EARS pattern (see `fragments/EARS.md`)

| EARS pattern | Natural `kind` |
|---|---|
| **When** (event-driven) | `test` — fire the event, assert the response |
| **If/Then** (unwanted) | `test`/`smoke` **negative** — provoke the trigger through the real path |
| **While** (state-driven) | `test` with a state fixture |
| **Where** (optional) | `test` as a matrix (flag on/off) |
| **shall continue to** (non-regression) | `test` — explicit regression case |

### Exit contract of `scripts/verify-gate.sh`

| exit | Meaning | Effect on `/build` and `/release` |
|---|---|---|
| `0` | 🟢 green (passed) | proceed |
| `2` | 🔴 red (failed) | **ABORT** |
| `3` | inconclusive (missing tool OR infra noise, e.g. a 403 from a WAF vs. the runner) | caller decides; does not count as red |
| `4` | `manual-ux`: requires a human signature | `/build` shows the checklist · `/release` requires the receipt |
| `5` | clarification-pending: an active ambiguity marker remains in the spec (see `fragments/CLARIFY.md`) | **STOP and return to the spec phase**. NOT a red build: drivers and loops **never** iterate the design because of it |
| `64` | block missing or malformed | invalid spec (no gate) |

## Golden rules

1. **`manual-ux` does not fake automation.** It is an explicit human gate (the antidote to
   "technically passes, aesthetically garbage"). `cmd: "N/A (manual-ux)"`; the `manual_fallback`
   is a checklist signed in the build report.
2. **Infra noise ≠ regression.** A smoke that gets a 403 from a WAF because of the runner's IP
   is inconclusive (exit 3), never red. Prefer running the smoke from the origin host.
3. **No gate crosses `/release`.** The gate is a precondition of deployment, not the deployment.
4. **Missing tool = inconclusive (3), not red.** Delivery is never blocked by an absent runtime.
5. **`eval` embeds its threshold in the `cmd`** (the runner exits non-zero below it) — the
   `threshold` field is documentation for humans.

## Ready-made examples (one per kind)

```yaml
# test — a worker with a test file next to it
verify_gate: { kind: test, cmd: "npm test -- src/checkout/logic.test.ts", pass_when: "exit 0", threshold: "—", manual_fallback: "—" }
```
```yaml
# smoke — a protected endpoint returns 401 without a token
verify_gate: { kind: smoke, cmd: "curl -sS -o /dev/null -w '%{http_code}' https://api.example.com/v1/orders", pass_when: "contains: 401", threshold: "—", manual_fallback: "—" }
```
```yaml
# manual-ux — mobile app, human gate
verify_gate: { kind: manual-ux, cmd: "N/A (manual-ux)", pass_when: "checklist signed", threshold: "—", manual_fallback: "smoke on a real phone: (1) the list opens in <2s; (2) rows scroll smoothly; (3) the resume button works; (4) the live badge appears; (5) back returns." }
```

> Note: the block may be multi-line (readable) or inline `{ ... }` (compact) — the parser reads
> `kind:`/`cmd:`/`pass_when:` at their first occurrence in either format. For `manual-ux` the
> `cmd` is ignored at execution time (it always falls through to the human gate, exit 4).

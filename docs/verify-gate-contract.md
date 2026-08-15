<!-- Language: **English** · [Português](pt-BR/verify-gate-contract.md) -->

# The Verify Gate contract

Complete reference for the mechanism the framework is named after. The fragment at
[`.claude/sdd/templates/fragments/VERIFY_GATE.md`](../.claude/sdd/templates/fragments/VERIFY_GATE.md)
is the version agents read; this document explains the reasoning behind it.

## The block

Every spec carries exactly one fenced `yaml` block under a `## Verify Gate` heading:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/pricing.test.ts"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

| Field | Required | Meaning |
|---|---|---|
| `kind` | always | `test` · `smoke` · `eval` · `typecheck` · `manual-ux` |
| `cmd` | except `manual-ux` | the executable command |
| `pass_when` | always | `exit 0` · `exit N` · `contains: TEXT` |
| `threshold` | `eval` only | the numeric target, documented for humans; enforcement lives in the `cmd` |
| `manual_fallback` | `manual-ux` only | the human checklist to walk and sign |

The parser reads the first occurrence of each key and takes everything after the first colon —
so value lines must not carry inline comments.

## Why six exit codes

A binary pass/fail is a lie in three common situations, and each lie has a cost.

**A missing tool is not a failure (`3`).** If the test runner is not installed on this machine,
the code is not wrong — you simply learned nothing. Returning red here trains people to ignore
red. Returning green here ships untested code. The honest answer is a third state that the
caller must resolve.

**Infrastructure noise is not a regression (`3`).** A smoke test that receives a 403 from a WAF
because of the runner's IP address says nothing about your endpoint. The gate detects this
specific shape — `kind: smoke`, a 403 in the output, and 403 not being what you expected — and
returns inconclusive with instructions to re-run from the origin host.

**Some acceptance is genuinely human (`4`).** Whether a screen feels premium is not a command.
The temptation is to write a test that technically passes and call it done. `manual-ux` refuses
that trade: it returns `4`, prints the checklist, and waits for a signature recorded in the
build report.

And one state that is not about the code at all:

**An unresolved question is not a failed build (`5`).** This is the subtlest one. If the spec
still contains an active ambiguity marker, the build has not failed — it should never have
started. The distinction matters because autonomous loops react to red by iterating: given `2`,
a driver will rewrite the design, over and over, on top of an assumption nobody validated.
Exit `5` is a separate state precisely so loops stop instead of iterating.

| exit | State | Caller obligation |
|---|---|---|
| `0` | green | proceed |
| `2` | red | **abort**; fix code, or iterate the spec if the defect is in the spec |
| `3` | inconclusive | resolve explicitly; never record as green, never count as red |
| `4` | human signature required | show `manual_fallback`, stop until the receipt is recorded |
| `5` | clarification pending | **stop**, return to `/define`; never iterate the design |
| `64` | invalid or missing block | the spec is not valid |

## The ambiguity marker

Active canonical form — the only one the scanner detects, and only outside code fences:

```
[NEEDS CLARIFICATION: <specific question>]
```

Every documentation reference to it — in templates, fragments, examples — must sit inside a code
fence or drop the brackets. This convention exists because the alternative is a template that
blocks every spec written from it. The scanner strips fenced blocks (including fences nested in
blockquotes) before searching.

## Choosing a `kind`

Derive it from the EARS pattern of the acceptance test it enforces:

| EARS pattern | Natural kind | Shape of the test |
|---|---|---|
| **When** (event-driven) | `test` | fire the event, assert the response |
| **If/Then** (unwanted) | `test` or `smoke`, **negative** | provoke the undesired trigger through the real path |
| **While** (state-driven) | `test` | build the state fixture, assert under it |
| **Where** (optional feature) | `test` | run with the flag on and off |
| **shall continue to** (non-regression) | `test` | an explicit regression case |

A negative test must go through the real path. Mocking the failure you are testing for proves
that your mock works.

## Anti-patterns

| Never | Instead |
|---|---|
| `cmd: "manually check that it works"` | A command, or `kind: manual-ux` with a real checklist |
| `kind: test` with an empty or `N/A` cmd | Invalid — the gate returns `64` |
| Marking a UX criterion as `test` to "pass technically" | If the value is perceived, it is `manual-ux` |
| Treating `3` as green because you are in a hurry | Resolve it, or record it as unresolved in the report |
| Loosening `pass_when` until it passes | That is deleting the acceptance criterion with extra steps |

## Testing the gate itself

Four fixtures pin the contract:

```bash
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md  # 5
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CLARIFY_RESOLVED.md     # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_TOKEN_IN_FENCE.md       # 0
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CONTROL.md              # 0
```

Run these after any change to `verify-gate.sh`. The third one — a marker that appears only inside
a fence — is the false-positive guard, and it is the one that breaks when someone "simplifies"
the fence handling.

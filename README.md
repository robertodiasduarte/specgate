<!-- Language: **English** · [Português](README.pt-BR.md) -->

# SpecGate

**Executable acceptance, not prose.**

SpecGate is a spec-driven development framework for coding agents. Its distinguishing
mechanism is one line of YAML that every spec must carry:

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/pricing.test.ts"
  pass_when: "exit 0"
```

That block is not documentation. `scripts/verify-gate.sh` runs it, and `/build` and `/release`
treat its exit code as blocking. Acceptance stops being a paragraph a human skims and becomes a
command a machine executes.

---

## Why this exists

Spec-driven development frameworks agree on the workflow — describe the work, plan it, build it.
They disagree on what "done" means. In most of them, done is decided by reading markdown and
ticking checkboxes: a human (or an agent) judges prose against prose.

That works until you let an agent loop. An autonomous loop needs a stop condition it cannot
argue with, and "the spec says the checkout should be fast" is not one. Without an executable
gate, autonomy produces garbage at scale — the loop runs, but against what does it stop?

SpecGate's answer: **the acceptance criterion is a command with an exit code.** Everything else
in the framework exists to make that command trustworthy — a requirements grammar so criteria
are testable, an ambiguity protocol so nobody guesses, and a graded release verdict so shipping
with a known gap is a recorded decision rather than a silence.

See [docs/comparison.md](docs/comparison.md) for how this compares to Spec-Kit, OpenSpec, BMAD,
Kiro and Tessl, and how it relates to the practices of Andrej Karpathy, Boris Cherny and
Peter Steinberger.

---

## The five mechanisms

| Mechanism | What it does | Where |
|---|---|---|
| **Verify Gate** | Acceptance as an executable command with a six-state exit contract (`0/2/3/4/5/64`), including *inconclusive* and *needs a human signature* — because "red or green" is a lie when a tool is missing or the criterion is aesthetic | [`fragments/VERIFY_GATE.md`](.claude/sdd/templates/fragments/VERIFY_GATE.md) · [`scripts/verify-gate.sh`](scripts/verify-gate.sh) |
| **EARS grammar** | Acceptance tests in a constrained grammar (When / While / If-Then / Where / shall). Each pattern maps onto a test type, and the *unwanted behaviour* pattern forces you to name the failure mode before building it | [`fragments/EARS.md`](.claude/sdd/templates/fragments/EARS.md) |
| **Clarify protocol** | Ambiguity becomes a marker in the spec, never a silent assumption. An active marker returns exit `5` and stops the pipeline — a state distinct from failure, so loops never "fix" an ambiguous spec by iterating the design | [`fragments/CLARIFY.md`](.claude/sdd/templates/fragments/CLARIFY.md) |
| **Graded verdict** | Releases end in PASS / CONCERNS / FAIL / WAIVED. A waiver is human-only, class-restricted and requires a written reason | [`commands/release.md`](.claude/commands/release.md) |
| **Adversarial review contract** | A second-vendor review answers in a fixed format (verdict, ≤3 ranked risks, specific fixes, what to ignore) and every note is applied or rebutted in writing — never dropped in silence | [`fragments/ADVISOR_CONSULT.md`](.claude/sdd/templates/fragments/ADVISOR_CONSULT.md) |

---

## Workflow

```text
/brainstorm  →  /define  →  /design  →  /build  →  /release
   (optional)      ↑          ↑           │            │
                   └──────────┴───────────┘            │
                    /iterate feeds corrections back    │
                                                       ▼
                          Verify Gate runs here, and again here — blocking both times
```

`/ux-review` is an optional gate between `/define` and `/design` for user-facing work.
`/build` also supports opt-in autonomy modes (`--mode ralph`, `--mode briefs`) that use the
Verify Gate as their stop condition.

---

## Install

SpecGate is files, not a package. Copy two directories into your repository:

```bash
git clone https://github.com/<owner>/specgate.git
cp -r specgate/.claude your-project/
cp -r specgate/scripts your-project/
cp specgate/sdd.config.example.yaml your-project/sdd.config.yaml
```

Then edit `sdd.config.yaml` to point the slots (`{{TEST_CMD}}`, `{{DEPLOY_CMD}}`, …) at your
project's real commands. The commands reference those slots — nothing is hardcoded.

Full walkthrough: [docs/quickstart.md](docs/quickstart.md) · adapting it to your stack:
[docs/adaptation-guide.md](docs/adaptation-guide.md).

**Requirements:** bash, git, and whatever test runner your gates call. `gitleaks` only if you
use the publication gate.

---

## Try it in two minutes

```bash
# a spec with an unresolved ambiguity halts the pipeline (exit 5)
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_NEEDS_CLARIFICATION.md; echo "exit=$?"

# the same spec, ambiguity resolved (exit 0)
scripts/verify-gate.sh .claude/sdd/fixtures/DEFINE_FIXTURE_CLARIFY_RESOLVED.md; echo "exit=$?"
```

Those four fixtures are the framework's own regression suite: they pin the exit contract, so a
change to `verify-gate.sh` that breaks it fails loudly.

---

## Status and provenance

SpecGate grew out of two years of daily production use in a private codebase, and is published
as a curated snapshot — see [CONTRIBUTING.md](CONTRIBUTING.md) for what that means for issues
and pull requests.

It began as a customization of [AgentSpec](https://github.com/luanmorenommaciel/agentspec) by
Luan Moreno Maciel (MIT). The phase structure descends from that work; the Verify Gate, the
clarify protocol, the graded verdict and the review contract are additions. See
[NOTICE](NOTICE).

Licensed under the [MIT License](LICENSE).

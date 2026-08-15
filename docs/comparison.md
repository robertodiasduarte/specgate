<!-- Language: **English** · [Português](pt-BR/comparison.md) -->

# How SpecGate compares

*Landscape reviewed August 2026. Star counts and versions are point-in-time; capabilities change.
Where this document is wrong about another project, it is wrong by accident — corrections welcome.*

This is not a "why we win" page. The frameworks below solve real problems well, and three of
them are far more widely adopted than this one. The purpose here is to state precisely what
SpecGate does differently, so you can tell whether that difference matters for your work.

---

## The one-line difference

**Every spec-driven framework produces a spec. SpecGate makes the spec carry a command that
decides whether the work is done.**

In Spec-Kit, OpenSpec, BMAD, Kiro and Tessl, acceptance is evaluated by reading: a human or an
agent compares the implementation against written criteria and ticks a box. In SpecGate,
acceptance is a `verify_gate` block that `scripts/verify-gate.sh` executes, returning one of six
exit codes that `/build` and `/release` are contractually required to honour.

That single change is what makes the rest coherent, and it is worth being honest about the cost:
writing an executable criterion is harder than writing a sentence. If your acceptance genuinely
cannot be expressed as a command — a visual judgment, a tone-of-voice call — SpecGate does not
pretend otherwise; it has a `manual-ux` kind that returns exit `4` and demands a human signature
rather than faking automation.

---

## Capability comparison

| Capability | Spec-Kit | OpenSpec | BMAD | Kiro | Tessl | **SpecGate** |
|---|---|---|---|---|---|---|
| Structured spec → plan → build flow | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Executable acceptance gate** | ❌ review | ❌ review | ❌ review | ❌ review | ❌ review | ✅ command + exit contract |
| Requirements grammar (EARS) | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ (adopted from Kiro) |
| Ambiguity marker with a mechanical stop | ✅ marker | ❌ | ❌ | ❌ | ❌ | ✅ marker **+ dedicated exit state** |
| Graded release verdict | ❌ | ❌ | ✅ (test architect) | ❌ | ❌ | ✅ + waiver taxonomy |
| Spec ↔ code reconciliation after build | ✅ `/analyze` | ✅ diffs | ⚠️ partial | ⚠️ partial | ✅ | ❌ *(planned)* |
| Specs as deltas against a canonical set | ❌ | ✅ | ❌ | ❌ | ⚠️ | ❌ *(under evaluation)* |
| Editor/IDE independent | ✅ | ✅ | ✅ | ❌ (own IDE) | ⚠️ | ✅ |
| Adoption | ~129k★ | ~65k★ | ~52k★ | vendor | vendor | new |

**Read the last two rows together.** SpecGate is new and has no community; Spec-Kit has a large
one. If you want a framework with contributors, plugins and answered issues, use Spec-Kit. If
you want the gate mechanism, take it from here — it is roughly 200 lines of bash and you can
port it into whatever you already run.

### Where the others are ahead

- **OpenSpec's specs-as-diffs** solves a problem SpecGate has not solved: when many branches run
  in parallel, each carrying a full spec, the canonical truth drifts. Deltas against a canonical
  capability set are a better answer than long-lived documents. This is on the roadmap here.
- **Spec-Kit's `/analyze`** checks bidirectional coverage — every requirement has a task, every
  task traces to a requirement. SpecGate has no equivalent yet, which is a real gap: its gate
  proves the *acceptance* passed, not that the manifest *covered* every requirement.
- **BMAD's test architect** originated the graded verdict adopted here. BMAD also carries a
  multi-persona model that its own v6 walked back on cost grounds — a useful negative result.
- **Kiro** invented the EARS integration this framework borrows. Its cost is IDE lock-in.

---

## Practitioner alignment

The three people below did not design this framework, and none of them has endorsed it. Their
published positions are cited because SpecGate is, in large part, an attempt to make their
advice mechanical rather than aspirational.

### Boris Cherny — verification is the top lever

Cherny's position, from Claude Code's best practices and his public notes, is that giving an
agent a way to **verify its own work** is the single highest-leverage intervention, worth a
multiple in output quality; and that an adversarial reviewer in a fresh session catches what the
author's context cannot.

*What SpecGate does with it:* the Verify Gate is that verification made mandatory and machine-read
— not a suggestion to "add tests" but a block the spec cannot omit (a missing or malformed gate
is exit `64`, an invalid spec). The adversarial review is formalized in
[`ADVISOR_CONSULT.md`](../.claude/sdd/templates/fragments/ADVISOR_CONSULT.md): a fixed answer
format capped at three ranked risks, plus a ledger where every note must be applied or rebutted
in writing.

### Andrej Karpathy — agentic engineering over vibe coding

Karpathy's framing distinguishes casual prompting from **agentic engineering**: keeping a human
on the "autonomy slider", demanding that assumptions surface as questions, insisting on
simplicity and surgical changes, and defining verifiable criteria before writing code. His
summary that the *harness* matters more than the model is the premise of this entire repository.

*What SpecGate does with it:* those points are five non-negotiable guidelines in the build
agent's prompt — an assumption becomes a question, nothing unrequested gets built, changes stay
surgical, criteria come before code, and evidence (a pasted command output) replaces the phrase
"successfully implemented". The autonomy slider is explicit: `/build` runs in-context by
default, `--mode ralph` per task in a fresh context, `--mode briefs` in parallel — and the mode
is always a human decision, never inferred.

### Peter Steinberger — most work does not need ceremony

Steinberger argues the opposite of what a framework author wants to hear: for small blast
radius, **just talk to the model**. Ceremony is overhead, and verification through observable
behaviour beats process.

*What SpecGate does with it:* takes it as a constraint rather than a rebuttal. A framework that
claims to be the only path is wrong, so the honest guidance is in
[docs/quickstart.md](quickstart.md): if the change is describable in one sentence and its blast
radius is small, skip the phases. The gate still helps there — as a one-line command, not a
document. SpecGate is for work where being wrong is expensive; Steinberger is right about
everything else.

---

## When NOT to use this

- **Solo, small, throwaway work.** The phases cost more than they return. Talk to the model.
- **You need an ecosystem today.** No plugins, no community, curated releases only.
- **Your acceptance is inherently visual.** You can use `manual-ux`, but then you are getting a
  disciplined checklist, not automation — decide whether that is worth the framework.
- **You already have a strong gate.** If your CI blocks merges on meaningful tests, you have the
  mechanism. Take the clarify protocol and the EARS grammar and skip the rest.

---

## Sources

- Spec-Kit — <https://github.com/github/spec-kit> · <https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/>
- OpenSpec — <https://github.com/Fission-AI/OpenSpec>
- BMAD-METHOD — <https://github.com/bmad-code-org/BMAD-METHOD>
- Kiro (specs, EARS) — <https://kiro.dev/docs/specs/> · EARS — <https://alistairmavin.com/ears/>
- Tessl — <https://tessl.io/blog/tessl-launches-spec-driven-framework-and-registry>
- Boris Cherny — <https://code.claude.com/docs/en/best-practices> · <https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny>
- Andrej Karpathy — <https://www.latent.space/p/s3>
- Peter Steinberger — <https://steipete.me/posts/just-talk-to-it>

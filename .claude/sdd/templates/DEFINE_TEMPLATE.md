# DEFINE: {Feature Name}

> One-sentence description of what we're building

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Date** | {YYYY-MM-DD} |
| **Author** | {author} |
| **Status** | {Draft / In Progress / Needs Clarification / Ready for Design} |
| **Clarity Score** | {X}/15 |

---

## Problem Statement

{1-2 sentences describing the pain point we're solving. Be specific about who has the problem and what the impact is.}

---

## Target Users

| User | Role | Pain Point |
|------|------|------------|
| {User 1} | {Their role} | {What frustrates them} |
| {User 2} | {Their role} | {What frustrates them} |

---

## Goals

What success looks like (prioritized):

| Priority | Goal |
|----------|------|
| **MUST** | {Primary goal - non-negotiable for MVP} |
| **MUST** | {Another critical goal} |
| **SHOULD** | {Important but can defer if timeline tight} |
| **COULD** | {Nice-to-have if time permits} |

**Priority Guide:**
- **MUST** = MVP fails without this
- **SHOULD** = Important, but workaround exists
- **COULD** = Nice-to-have, cut first if needed

---

## Success Criteria

Measurable outcomes (must include numbers):

- [ ] {Metric 1: e.g., "Handle 1000 requests per minute"}
- [ ] {Metric 2: e.g., "Achieve 99.9% uptime"}
- [ ] {Metric 3: e.g., "Response time under 200ms"}

---

## Acceptance Tests

> **EARS** grammar is mandatory for any new or revised DEFINE — patterns, worked examples
> and the pattern→gate `kind` map live in [`fragments/EARS.md`](fragments/EARS.md).
> Rules `/define` rejects when missing: ≥1 **If/Then** (unwanted behavior) AT whenever a
> plausible unwanted trigger exists; on a **bugfix**, ≥1 **shall continue to** clause
> (non-regression).

| ID | Pattern | Criterion (EARS) | Gate (`kind`) |
|----|---------|------------------|---------------|
| AT-001 | Event-driven | **When** {trigger}, the system **shall** {response} | test |
| AT-002 | Unwanted | **If** {unwanted trigger}, **then** the system **shall** {handling} | test / negative smoke |
| AT-003 | State-driven | **While** {state}, the system **shall** {response} | test |
| AT-00N | Non-regression (bugfix) | The system **shall continue to** {existing behavior} | test |

---

## Clarifications

> **Honesty rule:** ambiguity never becomes an assumption — it becomes an active marker at the
> exact spot of the doubt, in the canonical form below (full protocol, 9 categories and the
> mention convention in [`fragments/CLARIFY.md`](fragments/CLARIFY.md)):
>
> ```
> [NEEDS CLARIFICATION: <specific question>]
> ```
>
> While any active marker remains, `scripts/verify-gate.sh` returns **exit 5** and
> `/build` / `/release` stop. Resolve via AskUserQuestion (≤5 per round),
> fold the answer INTO THE BODY of the spec, and log it below.

### Session {YYYY-MM-DD}

- [x] ({category}) {question} → {answer}; folded into {section}

---

## Verify Gate

> **Executable acceptance gate (pass/fail).** `/build` (Step 5) and `/release` (Phase 0a) run it via
> `scripts/verify-gate.sh` and treat it as **BLOCKING** — it is a command, not prose.
> This is what enables loop engineering: it is the stop criterion of any loop.
> Full taxonomy: [`fragments/VERIFY_GATE.md`](fragments/VERIFY_GATE.md).

```yaml
verify_gate:
  kind: test
  cmd: "npm test -- src/checkout/pricing.test.ts"
  pass_when: "exit 0"
  threshold: "—"
  manual_fallback: "—"
```

**Fill in exactly one block** (replace the example above with the feature's real gate):

- `kind`: `test` | `smoke` | `eval` | `typecheck` | `manual-ux`
- `cmd`: executable command; for `manual-ux` use `"N/A (manual-ux)"`
- `pass_when`: `exit 0` (default) | `exit N` | `contains: TEXT`
- `threshold`: `eval` only (e.g. `"recall >= 0.80"` — the threshold is embedded in `cmd`)
- `manual_fallback`: `manual-ux` only — human checklist signed off in the BUILD_REPORT

**Rules:** `manual-ux` is a HUMAN gate (it does not fake automation). A smoke returning 403
because a WAF blocked the runner is *inconclusive*, not red (re-run it from the origin host).
⛔ No gate ever gets waived to cross `/release`.

Run it locally: `scripts/verify-gate.sh .claude/sdd/features/DEFINE_{FEATURE_NAME}.md`

---

## Out of Scope

Explicitly NOT included in this feature:

- {Item 1: What we're NOT doing}
- {Item 2: What's deferred to future}
- {Item 3: What's explicitly excluded}

---

## Constraints

| Type | Constraint | Impact |
|------|------------|--------|
| Technical | {e.g., "Must use existing database schema"} | {How this affects design} |
| Timeline | {e.g., "Must ship by Q1"} | {How this affects scope} |
| Resource | {e.g., "No additional infrastructure budget"} | {How this affects approach} |

---

## Technical Context

> Essential context for Design phase - prevents misplaced files and missed infrastructure needs.

| Aspect | Value | Notes |
|--------|-------|-------|
| **Deployment Location** | {src/ \| functions/ \| gen/ \| deploy/ \| custom path} | {Why this location} |
| **KB Domains** | {http-api, database, queues, payments, terraform, observability} | {Which patterns to consult} |
| **IaC Impact** | {New resources \| Modify existing \| None \| TBD} | {Terraform/Terragrunt changes needed} |
| **LLM Prompts** | {true \| false} | {Set true if the feature creates/edits runtime prompts — system prompts, pipeline passes, classifiers. When true, /design adds the LLM Prompts inventory and /build routes prompt authoring through your prompt-engineering skill (sdd.config.yaml).} |

**Why This Matters:**

- **Location** → Design phase uses correct project structure, prevents misplaced files
- **KB Domains** → Design phase pulls correct patterns from your knowledge base, if you keep one
- **IaC Impact** → Triggers infrastructure planning, avoids "works locally" failures
- **LLM Prompts** → Conditional gate for the prompt-engineering step; avoids overhead on features with no LLM

**LLM Prompts — triggers for marking `true`:**

The feature likely involves runtime prompts if any of the signals below show up (literally in the feature text, or inferred from scope):

- Words: `LLM`, `GPT`, `Claude`, `Anthropic`, `OpenAI`, `Gemini`, `Vercel AI`
- Concepts: `system prompt`, `user prompt`, `prompt`, `embeddings`, `RAG`, `vector search`, `completion`, `classifier`, `synthesizer`, `pipeline pass`
- Paths: `functions/**/prompts/**`, `shared/templates-*.ts`, any handler calling `messages.create` / `chat.completions`
- Product surfaces: support chatbot, AI-assisted replies, summarizers, recommendation copy, KB indexer

When in doubt, mark `true` and justify it in **Notes**. Revert to `false` during `/design` only if the heuristic confirms no file in the manifest contains a runtime prompt.

---

## Assumptions

Assumptions that if wrong could invalidate the design:

| ID | Assumption | If Wrong, Impact | Validated? |
|----|------------|------------------|------------|
| A-001 | {e.g., "Database can handle expected load"} | {Would need caching layer} | [ ] |
| A-002 | {e.g., "Request volume stays under 1000/hour"} | {Would need rate limiting} | [ ] |
| A-003 | {e.g., "Users have modern browsers"} | {Would need polyfills for legacy support} | [ ] |

**Note:** Validate critical assumptions before DESIGN phase. Unvalidated assumptions become risks.

---

## Clarity Score Breakdown

| Element | Score (0-3) | Notes |
|---------|-------------|-------|
| Problem | {0-3} | {Why this score} |
| Users | {0-3} | {Why this score} |
| Goals | {0-3} | {Why this score} |
| Success | {0-3} | {Why this score} |
| Scope | {0-3} | {Why this score} |
| **Total** | **{X}/15** | |

**Scoring Guide:**
- 0 = Missing entirely
- 1 = Vague or incomplete
- 2 = Clear but missing details
- 3 = Crystal clear, actionable

**Minimum to proceed: 12/15**

---

## Open Questions

{List any remaining questions that need answers before Design phase. If none, state "None - ready for Design."}

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | {YYYY-MM-DD} | define-agent | Initial version |

---

## Next Step

**Ready for:** `/design .claude/sdd/features/DEFINE_{FEATURE_NAME}.md`

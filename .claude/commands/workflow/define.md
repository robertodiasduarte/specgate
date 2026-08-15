# Define Command

> Capture requirements and validate them in one pass (Phase 1)

## Usage

```bash
/define <input>
```

## Examples

```bash
# From a BRAINSTORM document (recommended after /brainstorm)
/define .claude/sdd/features/BRAINSTORM_ORDER_PROCESSING.md

# From meeting notes or raw input
/define notes/meeting-notes.md
/define "Build a subscription renewal pipeline for the customer dashboard"
/define docs/stakeholder-email.txt
```

---

## Overview

This is **Phase 1** of the 5-phase AgentSpec workflow:

```text
Phase 0: /brainstorm → .claude/sdd/features/BRAINSTORM_{FEATURE}.md (optional)
Phase 1: /define     → .claude/sdd/features/DEFINE_{FEATURE}.md (THIS COMMAND)
UX Gate: /ux-review  → .claude/sdd/reviews/UX_REVIEW_{FEATURE}.md
Phase 2: /design     → .claude/sdd/features/DESIGN_{FEATURE}.md
Phase 3: /build      → Code + .claude/sdd/reports/BUILD_REPORT_{FEATURE}.md
Phase 4: /release    → production + ledger .claude/sdd/releases/
```

The `/define` command combines what used to be Intake + PRD + Refine into a single, iterative phase. When fed a BRAINSTORM document, it extracts pre-validated requirements with minimal clarification needed.

---

## What This Command Does

1. **Extract** - Pull requirements from any input (notes, emails, conversations)
2. **Structure** - Organize into problem, users, goals, success criteria
3. **Validate** - Built-in clarity scoring (must reach 12/15 to proceed)
4. **Clarify** - Ask targeted questions for any gaps

---

## Process

### Step 1: Load Context

```markdown
Read(.claude/sdd/templates/DEFINE_TEMPLATE.md)
Read(.claude/CLAUDE.md)

# If file provided:
Read(<input-file>)
```

### Step 2: Classify Input

Identify the input type to guide extraction:

| Input Type | Pattern | Focus |
|------------|---------|-------|
| `brainstorm_document` | BRAINSTORM_*.md from /brainstorm | Pre-validated, extract directly |
| `meeting_notes` | Bullet points, action items | Decisions, requirements |
| `email_thread` | Re:, Fwd:, signatures | Requests, constraints |
| `conversation` | Informal language | Core problem, users |
| `direct_requirement` | Structured request | All elements present |
| `mixed_sources` | Multiple formats | Consolidate, deduplicate |

**Note:** When input is a BRAINSTORM document, extraction is streamlined because:
- Discovery questions are already answered
- Approaches have been evaluated
- YAGNI has been applied
- User has validated the direction

### Step 3: Extract Entities

Extract these elements from input:

| Element | Extraction Patterns |
|---------|---------------------|
| **Problem** | "We're struggling with...", "The issue is...", "Pain point:" |
| **Users** | "For the team...", "Customers want...", "Users need..." |
| **Goals** | "We need to...", "Goal is to...", "Success looks like..." |
| **Success Criteria** | "Success means...", "We'll know when...", "Measured by..." |
| **Acceptance Tests** | "Given/When/Then", "Test case:", "Scenario:" |
| **Constraints** | "Must work with...", "Can't change...", "Limited by..." |
| **Out of Scope** | "Not including...", "Deferred to...", "Excluded:" |

### Step 4.5: Write the Acceptance Tests in EARS (mandatory for any new or edited DEFINE)

`Read(.claude/sdd/templates/fragments/EARS.md)` and rewrite the extracted acceptance tests in
the EARS grammar (English keywords). **Refuse** the DEFINE (do not save) when:

- Any test falls outside the table's patterns (no When/While/If-Then/Where/shall keyword);
- The feature has a plausible undesired trigger (provider down, missing row, permission denied,
  full queue) and there is **no If/Then (unwanted) test** — the class of bug that escapes most often;
- It is a **bug fix** and there is no **"shall continue to" clause** (non-regression);
- There is an adjective without a number ("fast" → "under 2s").

Each test records the natural gate `kind` (pattern→kind map in the fragment) — input for Step 5.6.

> Older DEFINEs already in the archive are not converted retroactively (same precedent as the
> Verify Gate: the rule applies when the DEFINE is touched again).

### Step 4: Calculate Clarity Score

Score each element (0-3 points):

| Element | Score | Meaning |
|---------|-------|---------|
| Problem | 0-3 | Clear, specific, actionable |
| Users | 0-3 | Identified with pain points |
| Goals | 0-3 | Measurable outcomes |
| Success | 0-3 | Testable criteria |
| Scope | 0-3 | Explicit boundaries |

**Scoring Guide:**
- 0 = Missing entirely
- 1 = Vague or incomplete
- 2 = Clear but missing details
- 3 = Crystal clear, actionable

**Minimum to proceed:** 12/15 (80%)

### Step 5: Fill Gaps (if needed)

If score < 12, use `AskUserQuestion` with specific options:

```markdown
Example questions:
- "Who is the primary user: (a) internal team, (b) customers, (c) both?"
- "What's the timeline: (a) this sprint, (b) this quarter, (c) no deadline?"
```

### Step 5.4: Clarify — mark and resolve ambiguity (the honesty rule)

`Read(.claude/sdd/templates/fragments/CLARIFY.md)`. Throughout the WHOLE drafting of the DEFINE:

1. **Mark it, never guess.** Real ambiguity → an active marker exactly where the doubt is, in
   the fragment's canonical form (bracket + NEEDS CLARIFICATION + colon + question).
   Documentation mentions of the token go inside a code fence or without the brackets
   (the false-positive guard convention).
2. **Sweep the nine categories** of the fragment (scope, data model, UX flow, NFRs, integrations,
   edge cases, constraints, terminology, done signal) — each one Clear/Partial/Missing; Partial
   and Missing produce a marker.
3. **Resolve in rounds:** at most 5 questions via `AskUserQuestion` (multiple choice, recommended
   option first). The answer is **integrated INTO THE BODY of the spec** (it replaces the ambiguous
   text AND the marker) + one line in the `## Clarifications / ### Session YYYY-MM-DD` log.
4. **Mechanical gate:** the DEFINE is only ready with **zero active markers** —
   `scripts/verify-gate.sh` returns **exit 5** (clarification-pending) while one remains,
   and `/build`/`/release` stop.

### Step 5.5: Detect LLM Prompts (conditional gate for the prompt-engineering skill)

Run a heuristic over the extracted material + the input text to decide the value of the
`**LLM Prompts**` line in **Technical Context**.

**Signals (any 1 strong hit or 2 weak hits → `true`):**

| Category | Tokens |
|-----------|--------|
| Providers | `LLM`, any model vendor or model family named in the input |
| Concepts | `system prompt`, `user prompt`, `prompt`, `embeddings`, `RAG`, `vector search`, `completion`, `classifier`, `synthesizer`, `pipeline pass` |
| Loop (signal for the loop-specification skill in DESIGN) | `agentic loop`, `reason→act→observe`, `multi-pass`, `evaluator`/`judge`, `verifier`, `retry until convergence`, `generator-evaluator`, `refine until` |
| Paths | `**/prompts/**`, shared prompt-template modules, any service calling an LLM chat/completions API |
| Actors | a named assistant/agent persona, `chatbot`, `AI support answers`, `automated report writer`, `KB indexer` |

**Rules:**

- 0 hits → `false`. Record in **Notes**: "no LLM signal detected".
- 1 strong hit (explicit provider or path) → `true`. Record the signal in **Notes**.
- 2+ weak hits (concept without provider, actor without path) → `true`. Record the signals in **Notes**.
- 1 isolated weak hit → **ambiguous**. Fire `AskUserQuestion`:
  > "The feature mentions `<token>` but it is not clear whether it will generate/edit a runtime prompt. Set `LLM Prompts: true` (it will go through your prompt-engineering skill, configured in `sdd.config.yaml`, during `/build`) or `false` (zero overhead, but drift detection in `/build` may reopen it)?"

Either way, fill the `**LLM Prompts**` line with a literal `true` or `false` plus a justification
in **Notes**. The flag here is **binary** — the `one-shot` vs `loop` classification (the router
between your prompt-engineering skill and your loop-specification skill) happens in `/design`
Step 5.5, per inventory row. If there is a hit in the **Loop** category above, record in **Notes**:
"loop candidate — classify in DESIGN".

### Step 5.6: Verify Gate (MANDATORY — refuse a DEFINE without a gate)

Every DEFINE **must** ship with a `## Verify Gate` block filled with an **executable** gate
(not prose). It is the stop condition that `/build` (Step 5a) and `/release` (Phase 0a) run via
`scripts/verify-gate.sh`. Without it, the DEFINE is incomplete — **do not save**.

Derive the gate from the **Acceptance Tests** + **Success Criteria** already captured:

1. **Pick the `kind`** by the nature of the acceptance (see [`fragments/VERIFY_GATE.md`](../../sdd/templates/fragments/VERIFY_GATE.md)):
   - pure, testable logic → `test` (`{{TEST_CMD}}` from `sdd.config.yaml` — e.g. `npm test -- checkout.test.ts` / `pytest tests/orders -q`)
   - an endpoint answers as expected → `smoke` (`curl … -w '%{http_code}'`, `pass_when: contains: 401`)
   - quality with a threshold → `eval` (threshold embedded in the `cmd`)
   - types/compilation → `typecheck` (`{{TYPECHECK_CMD}}` — e.g. `tsc --noEmit` / `mypy .`)
   - **pure UX (mobile/PWA/aesthetics) → `manual-ux`** (human gate; `cmd: "N/A (manual-ux)"` + `manual_fallback` = checklist)
2. **Write an executable `cmd`** and an objective `pass_when`. For `manual-ux`, write the checklist in `manual_fallback`.
3. **Validate the block** with the parser before declaring the DEFINE ready:
   ```bash
   scripts/verify-gate.sh --print .claude/sdd/features/DEFINE_{FEATURE_NAME}.md
   ```
   (it must list kind/cmd/pass_when without error 64).

**Anti-patterns to refuse:**
- a prose gate ("manually test that it works") → demand a command or `kind: manual-ux` with a checklist.
- `kind: test` but an empty / `N/A` `cmd` → blocked.
- a UX feature marked as `test`/`smoke` just to "pass on technicalities" → if the value is aesthetic or perceived, it is `manual-ux`.

If the acceptance is genuinely ambiguous, fire `AskUserQuestion` offering the plausible kinds.

### Step 6: Generate Document

Write the structured document following the template, then save:

```markdown
Write(.claude/sdd/features/DEFINE_{FEATURE_NAME}.md)
```

---

## Output

| Artifact | Location |
|----------|----------|
| **DEFINE** | `.claude/sdd/features/DEFINE_{FEATURE_NAME}.md` |

**Next Step:** `/ux-review .claude/sdd/features/DEFINE_{FEATURE_NAME}.md`

---

## Quality Gate

Before saving, verify:

```text
[ ] Problem statement is clear and specific
[ ] At least one user persona identified
[ ] Success criteria are measurable
[ ] Acceptance tests are testable
[ ] Tests in EARS grammar (Step 4.5): a keyword in every test · >=1 If/Then when there is a plausible undesired trigger · a bug fix has >=1 "shall continue to"
[ ] Zero active clarification markers (Step 5.4) — running scripts/verify-gate.sh <DEFINE> does NOT return exit 5
[ ] Out of scope is explicit
[ ] Clarity Score >= 12/15
[ ] Technical Context "LLM Prompts" filled with true/false + Notes justifying it
[ ] ## Verify Gate filled with an executable kind+cmd+pass_when (or manual-ux with manual_fallback)
[ ] scripts/verify-gate.sh --print <DEFINE> lists the block without error 64
```

---

## Tips

1. **Be Specific** - "Improve performance" → "Reduce API latency to <200ms"
2. **Use Numbers** - "Handle many users" → "Support 1000 concurrent users"
3. **Test Criteria** - If you can't test it, it's not clear enough
4. **Scope Ruthlessly** - What's OUT is as important as what's IN

---

## References

- Agent: `.claude/agents/workflow/define-agent.md`
- Template: `.claude/sdd/templates/DEFINE_TEMPLATE.md`
- Previous Phase: `.claude/commands/workflow/brainstorm.md` (optional)
- Next Phase: `.claude/commands/workflow/ux-review.md`
- Then: `.claude/commands/workflow/design.md`

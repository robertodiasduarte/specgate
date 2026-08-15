# Build Command

> Execute implementation with on-the-fly task generation (Phase 3)

## Usage

```bash
/build <design-file>                 # NO flag: Step 3b analyses the case and RECOMMENDS a mode — the call is always the user's
/build <design-file> --mode ralph    # explicit flag = the call is already made (skips the Step 3b recommendation): the loop is delegated to the Ralph executor (fresh context per turn)
/build <design-file> --mode briefs   # explicit flag = the call is already made. EXPERIMENT: cheap workers in parallel with stateless briefs; the orchestrator compiles and verifies
```

> Without `--mode`, `/build` does **not** silently assume the in-context loop: it runs
> **Mode selection (Step 3b)** — analyses the manifest of the concrete case, recommends one of
> the three modes and asks via `AskUserQuestion`. The in-context loop is the *default of the
> recommendation* when the signals tie, not a shortcut that skips the question.

## Examples

```bash
/build .claude/sdd/features/DESIGN_CHECKOUT_API.md
/build DESIGN_USER_AUTH.md
/build .claude/sdd/features/DESIGN_CUSTOMER_DASHBOARD_POLISH.md --mode ralph
```

---

## Overview

This is **Phase 3** of the 5-phase AgentSpec workflow:

```text
Phase 0: /brainstorm → .claude/sdd/features/BRAINSTORM_{FEATURE}.md (optional)
Phase 1: /define     → .claude/sdd/features/DEFINE_{FEATURE}.md
Phase 2: /design   → .claude/sdd/features/DESIGN_{FEATURE}.md
Phase 3: /build    → Code + .claude/sdd/reports/BUILD_REPORT_{FEATURE}.md (THIS COMMAND)
Phase 4: /release  → production + ledger .claude/sdd/releases/
```

The `/build` command executes the implementation, generating tasks on-the-fly from the file manifest.

---

## What This Command Does

1. **Parse** - Extract file manifest from DESIGN
2. **Prioritize** - Order files by dependencies
3. **Select mode** - Analyse the concrete case, RECOMMEND one of the 3 modes (+ a pre-build second-opinion review) — the call is always the user's
4. **Execute** - Create each file with verification
5. **Validate** - Run tests after each significant change (+ recommend a post-build second-opinion review)
6. **Report** - Generate build report

---

## Process

### Step 1: Load Context

```markdown
Read(.claude/sdd/features/DESIGN_{FEATURE}.md)
Read(.claude/sdd/features/DEFINE_{FEATURE}.md)
Read(.claude/CLAUDE.md)
```

**Extract the `LLM Prompts` flag** from the DEFINE (Technical Context) and cross-check it against the **LLM Prompts** section of the DESIGN (the fragment attached when `true`):

- `LLM Prompts: true` in the DEFINE → the DESIGN **MUST** have a filled "LLM Prompts" section. If it is missing, **STOP** and ask for `/iterate DESIGN`.
- `LLM Prompts: false` in the DEFINE → the DESIGN **MUST NOT** have the section. The build proceeds normally but **drift detection** (Step 4) is armed.

### Step 2: Extract Tasks from File Manifest

Convert the file manifest to a task list:

```markdown
From DESIGN file manifest:
| File | Action | Purpose |

Generate:
- [ ] Create/Modify {file1}
- [ ] Create/Modify {file2}
- [ ] ...
```

### Step 3: Order by Dependencies

Analyze imports and dependencies to determine execution order.

### Step 3b: Mode selection (recommendation → the call is ALWAYS the user's)

**Before executing any manifest item**, analyse the specific case and recommend an execution
mode. The choice is made via `AskUserQuestion` — recommended option **first**, with
"(Recommended)" in the label and a rationale citing the decisive signal of the concrete case
(e.g. "17 files, 12 independent components with disjoint paths → fresh context per turn").

> **Exception:** if `/build` was invoked with an explicit `--mode`, the call has already been
> made — skip the mode question and record "mode fixed by flag" in the BUILD_REPORT. The
> pre-build second-opinion review question (below) still runs.

**Signals to gather (from the file manifest + the Technical Context of the DEFINE/DESIGN):**

| Signal | How to measure | Pushes toward |
|---|---|---|
| Number of files in the manifest | count the table rows | few (≤6) → default · many (≥10) → ralph/briefs |
| Cross-file coupling | schemas/RPCs/helpers/imports shared between items | high → **default** (one author remembers names/signatures) |
| Security surface | authorization rules, auth gates, migrations with logic | present → default/ralph (**hard exclusion from cheap workers**) |
| LLM Prompt items | the DEFINE flag + the DESIGN inventory | present → default/ralph (the builder gate stays with the orchestrator) |
| Volume of independent/similar items | N components with no mutual dependency and disjoint paths | high → **ralph** · high AND outside the exclusions → **briefs** |
| Context-rot risk | large manifest + extensive logic per item | high → **ralph** (clean turns, resumable via PROGRESS) |

**Comparison table (the recommendation criterion):**

| | Default (in-context) | `--mode ralph` | `--mode briefs` (experimental) |
|---|---|---|---|
| Cross-file coherence | ✅ High — one author remembers the schemas/names/signatures used | ⚠️ Depends on the spec — each turn re-derives from the DESIGN, may diverge in naming/helpers | ⚠️ Depends on the brief — poorly curated INPUTS diverge |
| Context hygiene in a long build | ⚠️ Context grows; risk of "rot" toward the end | ✅ Every turn is clean — immune to bloat | ✅ Stateless workers |
| Commits | At the end / per milestone | ✅ Atomic per task (granular rollback) | Per wave |
| Resumable if it dies midway | ⚠️ Loses the thread | ✅ The PROGRESS file resumes exactly where it stopped | ⚠️ Per wave (re-dispatches the current wave) |
| Token cost | Lower (does not re-read the whole spec every turn) | Higher (re-reads the spec per task) | Cheap workers; the orchestrator pays for compiling the briefs |
| Parallelism | ❌ Sequential | ❌ Sequential | ✅ Per dependency wave |
| Best when | Coupled files (shared schemas/RPCs, subtle logic) | Independent files in volume; long/interruptible builds | Parallelizable volume OUTSIDE security/LLM Prompts |

**Hard rules of the recommendation:**

- `--mode briefs` remains **experimental** (promotion gate in Step 4): only recommend it when,
  after removing the security items (authorization rules/gates/migrations with logic) and the
  LLM Prompt items, **relevant parallelizable volume is left** — and always labelled as an
  experiment in the option.
- Signals tie → recommend the **default** (in-context).
- Never decide alone: even with an obvious recommendation, the `AskUserQuestion` runs.

**In the SAME `AskUserQuestion`, a second question — a pre-build second-opinion review (of the DESIGN):**
a second-opinion review from a different model vendor has an uncorrelated error profile, and
fixing on paper is cheaper than fixing in code:

- **Recommend YES** when: new architecture with **≥3 files** in the manifest, OR the manifest
  touches security surface (authorization rules, gates, endpoint auth) or a public/cached route.
- **Recommend NO** (dispensable) for a trivial fix: 1-2 files, no contract change.
- If YES: request the review of `DESIGN_{FEATURE}` **before** Step 4, attaching the contract in
  [`fragments/ADVISOR_CONSULT.md`](../../sdd/templates/fragments/ADVISOR_CONSULT.md); every note
  enters the **Advisor Ledger** of the BUILD_REPORT as APPLIED|REBUTTED (never silence).

**Record in the BUILD_REPORT** (section "Mode selection"): the signals gathered, the
recommendation, the user's decision and — if there was a pre-build review — the ledger summary.

### Step 4: Execute Each Task

> **Option — `--mode ralph` (via an explicit flag OR chosen in Step 3b).**
> When ralph mode is selected, `/build` does **not** execute the manifest in a single context.
> Instead it **delegates the execution loop to the Ralph executor** (fresh context per task),
> treating the DESIGN's file manifest as the task list:
>
> 1. Ensure a PROGRESS file exists at `.claude/sdd/progress/PROGRESS_{FEATURE}.md` (create it if absent) —
>    seed the manifest rows as pending tasks (drift check and the prompt-engineering
>    gate still apply inside each turn).
> 2. **Respawn** `Agent(subagent_type: "the loop executor agent", "--mode ralph: do the NEXT task
>    from the manifest …")` — **one task + atomic commit + PROGRESS update per turn**.
> 3. Between turns, `/build` runs the **Verify Gate (Step 5a)** as the stop condition
>    (`scripts/verify-gate.sh <DEFINE>`): exit `0` for ✅; `2` continues (next turn);
>    `3` resolve; `4` human; it respects the `--max` budget (default 2× the number of manifest items).
> 4. On convergence, proceed to **Step 6 (BUILD_REPORT)** as usual, attaching the per-turn SHAs.
>
> The default mode (no flag) follows the in-context loop below, unchanged.

> **Option `--mode briefs` (via an explicit flag OR chosen in Step 3b — EXPERIMENTAL; NOT a default and never a recommendation unless parallelizable volume is left outside the exclusions).**
> An evolution of Ralph: instead of a fresh executor re-reading the whole spec every turn, the
> **orchestrator (a large-context model) compiles 1 self-contained brief per manifest item** —
> template and dispatch rules in [`fragments/WORKER_BRIEF.md`](../../sdd/templates/fragments/WORKER_BRIEF.md)
> — and dispatches **cheap workers in parallel, per dependency wave**:
>
> 1. **Waves:** extend Step 3 — items with no mutual dependency AND disjoint paths go in the same
>    wave; drift detection runs HERE, over the manifest, before any dispatch.
> 2. **Compile 1 brief per item** (SUBTASK · inline INPUTS · numbered ACCEPTANCE CRITERIA ·
>    OUTPUT FORMAT). Curating the INPUTS is the orchestrator's noble work.
> 3. **Dispatch the wave:** `Agent(general-purpose, model: <cheap model>, prompt: <brief>)`, several
>    in the same message. **Hard exclusions:** LLM Prompt items (→ prompt-engineering gate in the
>    orchestrator) and security surface (authorization rules/gates/migrations with logic) NEVER go
>    to a cheap worker.
> 4. **Verify the wave in the orchestrator:** acceptance criteria × result → PASS / FIX
>    (the retry ladder above, with a fresh FIX-brief) / ESCALATE. `INPUT GAP` in a reply = a badly
>    compiled brief → complete it and re-dispatch (it does not count on the ladder). Only then
>    release the next wave.
> 5. **Steps 5–6 untouched** (the Verify Gate is authoritative; the BUILD_REPORT gains a
>    "briefs dispatched × model × result × retries" table).
>
> **Promotion gate:** it only becomes a recommended mode with a green pilot (a low-risk
> frontend-only feature, with gate/retries/cost/wall-clock metrics vs the baseline) plus an
> explicit human decision.

For each file (default in-context loop):

> **Execution guidelines (non-negotiable):** follow the section of the same name in
> [`build-agent.md`](../../agents/workflow/build-agent.md) — an assumption becomes a question ·
> simplicity · surgical change · criterion before code · evidence, not declaration.

1. **Drift detection (always, even with `LLM Prompts: false`):**
   - Does the path match `**/prompts/**` OR a shared prompt-template module?
   - Does the content to be written contain an LLM SDK chat/completions call or a `system:` parameter?
   - **If YES and the DEFINE says `false`** OR **YES and the file is not in the DESIGN's "LLM Prompts" inventory** → **STOP** and fire `AskUserQuestion`:
     > "File `<path>` smells like a runtime prompt but is not in the DESIGN inventory (LLM Prompts=`<flag>`). (a) Pause and run `/iterate DESIGN_{FEATURE}` to add it; (b) confirm it is a false positive and continue, recording the event under **Drift detected** in the BUILD_REPORT."
   - **If YES and the file is in the inventory** → go to step 2 (builder router).
   - **If NO** → skip to step 3 (write directly).

2. **Prompt builder gate — router between your loop-specification skill and your prompt-engineering skill (only when the file is in the DESIGN's "LLM Prompts" inventory):**
   - Read the **`Type`** column of the inventory row (the DESIGN has already classified it). If the row has no `Type` (an older DESIGN) → triage inline: *does the process re-prompt the LLM based on its own previous output?* Yes → `loop`; no → `one-shot`. When in doubt, `AskUserQuestion`.
   - **If `Type = loop`:** invoke your **loop-specification skill** first with the compiled contract → it produces the LOOP_SPEC. Then, for **each LLM stage** of the LOOP_SPEC, invoke your **prompt-engineering skill** (configured in `sdd.config.yaml`) with that stage's contract. Materialize the harness + paste each prompt into its destination. Skip the rest of step 2 (which is the one-shot flow).
   - **If `Type = one-shot`** (continue below):
   - Compile the skill's `args` by joining: the inventory row + the DESIGN's "Per-prompt contract" block + concrete reference material (Read the referenced files).
   - Invoke your **prompt-engineering skill** with the compiled contract.
   - Receive the TXT BLOCK.
   - **DO NOT end the turn after receiving the TXT BLOCK.** The TXT BLOCK is intermediate input for `/build`, not a final output. In the SAME turn: wrap it in `export const SYSTEM_PROMPT_{NAME} = \`...\` as const;` and `Write` it to the destination path. Never pause asking to "continue" between the skill and the Write — the skill's instruction that "the output is a TXT BLOCK" applies to its own scope, not to `/build`'s.
   - Wrap it in `export const SYSTEM_PROMPT_{NAME} = \`...\` as const;` at the destination path.
   - **Do not reopen DESIGN decisions** (provider, model, output type). If a decision has to change, stop and run `/iterate DESIGN` before invoking the skill.

3. **Write** — Create the file following code patterns from DESIGN.
4. **Verify** — Run verification command (lint, type check, import test).
5. **Mark Complete** — Update progress; if the file went through the skill, record the operation for the "Prompts Generated/Refactored" section of the BUILD_REPORT.

### Step 5: Run Full Validation

After all files are created, run the validation in the order below. **The DEFINE's Verify Gate is
the AUTHORITATIVE and BLOCKING acceptance gate** — the generic checks are complementary and
"if applicable" (they depend on your project's stack).

**5a. The DEFINE's Verify Gate (BLOCKING):**

```bash
scripts/verify-gate.sh .claude/sdd/features/DEFINE_{FEATURE}.md
```

Interpret the **exit code** (contract in [`fragments/VERIFY_GATE.md`](../../sdd/templates/fragments/VERIFY_GATE.md)):

| exit | Meaning | `/build` action |
|---|---|---|
| `0` | 🟢 green gate | proceed to 5b |
| `2` | 🔴 red gate | **ABORT the build.** Do not produce a successful BUILD_REPORT. Fix the code and re-run the gate (or `/iterate` if the defect is in the DESIGN/DEFINE). |
| `3` | inconclusive (missing tool OR a 403 from a WAF vs. the runner) | do **NOT** mark green. Record it in the BUILD_REPORT; if it is a smoke 403, re-run it from the origin host; if it is a missing tool, install it or run where the tool exists. |
| `4` | `manual-ux` → human gate | **Show the `manual_fallback` (checklist) to the human** and STOP until a receipt. Do not auto-pass. The receipt (who signed + date + result) goes in the BUILD_REPORT. |
| `5` | clarification-pending | **STOP and hand back to the human** — an active ambiguity marker remains in the DEFINE (protocol in `fragments/CLARIFY.md`). It is NOT a red build: do not fix code, do not `/iterate` the DESIGN. |
| `64` | block missing or malformed | invalid DEFINE — go back to `/define` (the gate has been mandatory since the start). |

> **Hard rule:** `/build` may only declare success with the Verify Gate at `0` (or `4` with a
> recorded human receipt). `2` aborts; `3` requires explicit resolution before proceeding.

**5b. Generic checks (complementary, if applicable):**

```bash
# From sdd.config.yaml — e.g. npm test, pytest
{{TEST_CMD}}

# From sdd.config.yaml — e.g. tsc --noEmit, mypy .
{{TYPECHECK_CMD}}
```

**5c. Post-build second-opinion review (recommendation → the call is the user's):**

With the Verify Gate green (or `4` with a receipt), **recommend** a second-opinion review from a
different model vendor before the BUILD_REPORT:

- **Recommend YES** when: the diff touches security (authorization rules, gates, endpoint auth),
  a public/cached route, subtle cross-file logic, or the build ran in ralph/briefs mode (multiple
  authors → a divergence risk that one fresh reviewer catches).
- **Recommend NO** for a trivial fix (1-2 files, no contract change) — Phase 0 of `/release`
  already covers it.
- Ask via `AskUserQuestion` (recommendation first). If YES, **the agent itself triggers it** —
  no terminal, no TUI:
  1. First a dry run that validates the scope and the diff.
  2. The real execution ALWAYS with `run_in_background: true` (a reasoning model can blow past a
     synchronous timeout). No polling; the notification arrives on its own.
  3. When it finishes, read the review output under `.claude/sdd/reviews/EXTERNAL_REVIEW_<ts>/`
     and synthesize it deduplicated, verifying HIGH/MED findings in the code before confirming
     (an external reviewer only sees the diff — context false positives are common).
- Findings come back into `/build`: every note enters the **Advisor Ledger** of the BUILD_REPORT
  as APPLIED|REBUTTED (never silence). A HIGH applied → re-run the Verify Gate (5a) before Step 6.
- A review **never replaces a real smoke test** (a structural limit: a reviewer only sees git state).

### Step 6: Generate Build Report

```markdown
Write(.claude/sdd/reports/BUILD_REPORT_{FEATURE}.md)
```

**Attach the prompts fragment (conditional):**

- `LLM Prompts: true` in the DEFINE → add a **"Prompts Generated/Refactored"** section between **"Files Created"** and **"Verification Results"** in the BUILD_REPORT. Fill in the executed inventory + the per-prompt detail + drift detected (even if empty: record "No drift detected.").
- `LLM Prompts: false` but drift was detected during the build → **still attach** the fragment, with an empty inventory but the "Drift detected" section filled. It documents the decision for the next feature.
- `LLM Prompts: false` and zero drift → do not attach.

---

## Output

| Artifact | Location |
|----------|----------|
| **Code** | As specified in DESIGN file manifest |
| **Build Report** | `.claude/sdd/reports/BUILD_REPORT_{FEATURE}.md` |

**Next Step:** `/release <description of what to release>` (when ready) — Phase 4 is `/release`,
which runs the Verify Gate again in Phase 0a and ships to production with one human OK.

---

## Execution Loop

The build agent follows this loop for each task:

```text
┌─────────────────────────────────────────────────────┐
│                    EXECUTE TASK                      │
├─────────────────────────────────────────────────────┤
│  1. Read task from manifest                         │
│  2. Write code following DESIGN patterns            │
│  3. Run verification command                        │
│     └─ If FAIL → retry ladder (below)               │
│  4. Mark task complete                              │
│  5. Move to next task                               │
└─────────────────────────────────────────────────────┘
```

**Retry ladder — FIX = FRESH RE-DISPATCH, never a reply:**

```text
FAIL 1st time → fix in-context (trivial error: lint, typo, import).
FAIL 2nd time → FRESH RE-DISPATCH is mandatory: discard the previous approach and
              re-execute the task from a FIX-brief containing ONLY:
              (1) the acceptance criterion that failed, quoted VERBATIM;
              (2) the error output, VERBATIM;
              (3) the instruction "treat this as a new task — do NOT assume the
                  previous attempt was nearly right".
              The FIX-brief carries NEITHER the code NOR the reasoning of the
              previous attempt — with no history, there is nothing to defend.
              · Default mode → Agent(a NEW subagent) with the FIX-brief.
              · Ralph mode   → a RETRY entry in the PROGRESS file; the next turn
                is born clean.
FAIL 3rd time → STOP and report it in the BUILD_REPORT — never "work around" the criterion.
```

> **Why:** retrying in the same context anchors the model to the wrong hypothesis from the 1st
> attempt — it patches at the margin instead of reconsidering. The re-dispatch cuts the anchor;
> the verbatim criterion guarantees the new attempt aims at the right acceptance.

---

## Quality Gate

Before marking complete, verify:

```text
[ ] Mode selection (Step 3b) recorded in the BUILD_REPORT: signals + recommendation + the user's decision (or "mode fixed by flag")
[ ] Adversarial reviews decided with a receipt: pre-build (Step 3b) and post-build (Step 5c) — YES with a ledger or NO with a justification
[ ] All files from manifest created
[ ] The DEFINE's Verify Gate run via scripts/verify-gate.sh → exit 0 (or 4 with a human receipt)
[ ] The Verify Gate is NOT at 2 (red) nor at an unresolved 3 (inconclusive)
[ ] All verification commands pass
[ ] Lint check passes
[ ] Tests pass (if applicable)
[ ] No TODO comments left in code
[ ] Build report generated (with the Verify Gate result + the receipt if manual-ux)
[ ] If LLM Prompts=true: every DESIGN inventory row has a receipt in the BUILD_REPORT "Prompts Generated/Refactored"
[ ] Drift detected during the build: recorded in the BUILD_REPORT with the decision and the action (even with zero drift, mark "No drift detected.")
[ ] If an advisor was consulted (second-opinion review): every note has a decision (APPLIED|REBUTTED) in the BUILD_REPORT's Advisor Ledger
```

---

## Tips

1. **Follow the DESIGN** - Don't improvise, use the code patterns
2. **Verify Incrementally** - Test after each file, not at the end
3. **Fix Forward** - If something breaks, fix it immediately
4. **Self-Contained** - Each file should be independently functional
5. **No Comments** - Code should be self-documenting

---

## Handling Issues During Build

If you encounter issues:

| Issue | Action |
|-------|--------|
| Missing requirement | Use `/iterate` to update DEFINE |
| Architecture problem | Use `/iterate` to update DESIGN |
| Simple bug | Fix immediately and continue |
| Major blocker | Stop and report in build report |
| A stubborn red Verify Gate / a loop with no way out | (Optional, the user's call) delegate the investigation to a second-opinion review from a different model vendor: "investigate why Verify Gate Y fails in <context>" — a second head with an uncorrelated error profile to break the deadlock. **Attach the response contract from [`fragments/ADVISOR_CONSULT.md`](../../sdd/templates/fragments/ADVISOR_CONSULT.md)** to the prompt and lay the notes out in the BUILD_REPORT's Advisor Ledger (applied/rebutted, never silence). |

---

## References

- Agent: `.claude/agents/workflow/build-agent.md`
- Template: `.claude/sdd/templates/BUILD_REPORT_TEMPLATE.md`
- Verify Gate: `.claude/sdd/templates/fragments/VERIFY_GATE.md` · runner: `scripts/verify-gate.sh`
- Next Phase: `.claude/commands/release.md`

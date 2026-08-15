# Fragment: WORKER BRIEF — stateless dispatch of a manifest item (`/build --mode briefs`)

> **Use:** in `--mode briefs`, the orchestrator (a large-context model) compiles **one brief per
> file-manifest item** and dispatches cheap workers in parallel, by dependency wave. The worker
> sees **ONLY this brief** — never the full design or spec. Build quality depends on how well the
> INPUTS are curated: an incomplete brief produces a confident, wrong worker. All four sections
> are mandatory.

---

## Template (compiled by the orchestrator, one per item)

```markdown
## SUBTASK
{one line: action + file, copied from the manifest row}

## INPUTS (complete and INLINE — you do NOT have access to the design or spec)
- {the design excerpt relevant to THIS file: code patterns, contracts, signatures}
- {current contents of the file, if Action=Modify; or of the files it imports}
- {applicable conventions — e.g. the project's style guide for this layer}
- CLOSED DECISIONS (do not reopen): {provider, model, names, routes — whatever the design already settled}

## ACCEPTANCE CRITERIA (numbered, pass/fail — the orchestrator will verify them)
1. {functional criterion extracted from the design for this file}
2. The verification command passes: `{tsc --noEmit … / node --check … / php -l …}`
3. No file other than {path} was touched.

## OUTPUT FORMAT
- Write to {exact path}. No explanatory comments. No TODOs.
- If an INPUT is missing or contradictory: prefix your reply with
  `INPUT GAP: {one line}` and proceed with what you have — NEVER invent a contract or signature.
- Return only the essentials (status + INPUT GAP if any) — no preamble, no "improvements"
  outside the SUBTASK.

## GUIDELINES (non-negotiable)
- Surgical: only the lines in the SUBTASK; do not refactor or "improve" adjacent code.
- Simple: nothing that was not asked for (no speculative abstraction or configurability).
- Evidence: run the verification command and paste the output — never declare without running.
```

---

## Dispatch rules (orchestrator)

1. **Waves by dependency AND by disjoint path** — items with no mutual dependency and distinct
   paths go in the same wave (parallel, same message). Path collision → separate waves.
2. **Drift detection runs BEFORE dispatch**, over the manifest, in the orchestrator — never in the worker.
3. **Hard exclusions (these NEVER go to a cheap worker):**
   - items in the LLM-prompt inventory → orchestrator plus the prompt-engineering gate (quality over cost);
   - **security surface** (authorization rules, auth gates, migrations containing logic) →
     orchestrator; a migration with logic still requires a real smoke test.
4. **Per-wave verification, in the orchestrator:** incremental command + result × acceptance
   criteria → **PASS / FIX / ESCALATE**. FIX follows the retry ladder in `build.md`
   (a fresh FIX brief carrying the criterion and the error verbatim). Only then does the next
   wave start.
5. **`INPUT GAP` in a reply** is a defect in brief compilation, not in the worker: the
   orchestrator completes the INPUT and re-dispatches (it does not count as a ladder failure).
6. **Steps 5–6 of `/build` are untouched:** `scripts/verify-gate.sh` remains the authoritative,
   blocking gate; the build report gains a "briefs dispatched × model × result × retries" table.

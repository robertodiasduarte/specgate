# Fragment — Clarify (the ambiguity marker protocol)

> Reusable. Read by `/define` (Step 5.4). **Honesty rule:** faced with ambiguity, the agent
> **marks it, never guesses** — a silent assumption is the most expensive class of error in
> the funnel, because it only surfaces during the smoke test or in production.

## The marker

The canonical active form (the only one `verify-gate.sh` detects, and only outside code fences):

```
[NEEDS CLARIFICATION: <specific question>]
```

- It goes **exactly where the ambiguity is** (Problem, acceptance tests, Constraints — any section).
- While an active marker exists, `scripts/verify-gate.sh` returns **exit 5**
  (`clarification-pending`): `/build` and `/release` **stop and return to `/define`**.
  It is not a red build gate — it **never** triggers a design iteration.
- `--print` is exempt (authoring aid while the spec is being written).

### Mention convention (false-positive guard)

Every **documentation** reference to the marker — in a template, fragment, example or history —
goes **inside a code fence** (as above) or **without the brackets** (e.g. "the NEEDS
CLARIFICATION protocol…"). The canonical form in open prose IS an active marker, and it blocks.

## The nine categories (sweep ALL of them before declaring a spec ready)

| # | Category | Guiding question |
|---|---|---|
| 1 | Scope | What is in and out? Which slice is this? |
| 2 | Data model | Which entities/columns/states? Who owns the table? |
| 3 | UX flow | What does the user see in each state (empty, error, success)? |
| 4 | NFRs | Latency, volume, cost, scheduling window? |
| 5 | Integrations | Which external contract and which limits? |
| 6 | Edge cases | Undesired trigger, missing row, permission denied, full queue? |
| 7 | Constraints | What must not change? Which precedent applies? |
| 8 | Terminology | Any domain term with two readings? |
| 9 | Done signal | How do we know it is finished? What is the pass/fail command? |

For each category: **Clear / Partial / Missing**. Partial and Missing produce a marker.

## Resolution protocol

1. **At most 5 questions per round**, as multiple choice (2–4 options), **recommended option
   first**. More than 5 pending? Priority: what changes architecture > scope > the rest;
   run another round afterwards.
2. **The answer is integrated INTO THE BODY of the spec**: replace the ambiguous text (and the
   marker) with the decision — never leave the answer in an appendix while the contradictory
   text survives.
3. **Log it** under `## Clarifications`:
   ```markdown
   ## Clarifications
   ### Session 2026-01-15
   - [x] (6-edge cases) Does a full queue drop or enqueue? → enqueue with a 24h TTL; integrated into AT-004
   ```
   (Format: `- [x] (category) question → answer; integrated into <section>`. Without the
   canonical marker form — mention convention.)
4. **Mechanical gate:** a spec is ready when **zero markers are active**. `verify-gate.sh`
   returns exit 5 while one remains.

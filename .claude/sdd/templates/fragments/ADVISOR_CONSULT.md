# Fragment — Advisor Consult (contract for an adversarial second-vendor review)

> **Use:** whenever a formal review by a second model vendor is triggered at one of the
> framework's checkpoints — design before build, a stubborn red gate during build, or the
> pre-release review. **When** to consult is your own policy; this fragment defines the
> **format** of the request, of the answer, and of what happens to each note.
> Informal exploratory questions stay free-form — the contract applies to formal checkpoints.

---

## 1. What goes INTO the consultation (compiled by the orchestrator)

```markdown
TYPE: plan-review (design, pre-build) | delivery-review (post-build, pre-release)
      | conflict (results contradict each other) | judgment call
TASK + SUCCESS CRITERIA: {pasted from the spec — Verify Gate + acceptance criteria}
QUESTION: {ONE focused question — never "review everything"}
MATERIAL: {the diff/design/output, inline}
```

One consultation = one question. If there are two questions, that is two consultations (or the
second one did not deserve an advisor).

## 2. REQUIRED answer format (append verbatim to the advisor's prompt)

```text
Answer EXACTLY in this format, 300 words maximum in total:

1. VERDICT — one line (e.g. "shippable with one fix" / "do not ship: risk X" /
   "wrong approach: reconsider Y").
2. TOP RISKS — one to three failure points, RANKED by severity. Never more than three.
3. SPECIFIC FIXES — concrete changes citing file/line/snippet. Nothing vague.
4. WHAT TO IGNORE — what is being overrated and should NOT become work.

Do not rewrite the material. Do not praise (if it is good, one line in the VERDICT is enough).
Spend words only where they change a decision.
```

**Why this format:** the cap of three risks forces ranking (the critical finding does not drown
in fifteen nits); `WHAT TO IGNORE` self-calibrates the reviewer — it is hard to inflate findings
when the answer itself must declare which ones do not matter.

## 3. Disposition of the notes (mandatory — Advisor Ledger)

**Every advisor note is APPLIED or REBUTTED in writing. Never dropped in silence.**

A table in the phase report (build report, release report, design changelog):

```markdown
### Advisor Ledger

| # | Note | Severity | Decision | Evidence |
|---|------|----------|----------|----------|
| 1 | {one-line summary} | HIGH | APPLIED | commit `abc123` |
| 2 | {one-line summary} | LOW  | REBUTTED | {reason, one line} |
```

- **APPLIED** → evidence is the commit/file of the fix, or a checklist/automation item created
  (medium and low notes become a fix, an automation or a checklist — never "accepted and forgotten").
- **REBUTTED** → a one-line written reason. A note rebutted today with a recorded reason is gold
  when the same topic resurfaces in another feature.
- Items in the advisor's `WHAT TO IGNORE` block do not enter the ledger (that block already is
  their disposition).

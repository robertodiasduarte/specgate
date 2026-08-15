---
description: Protected release pipeline to production (feature or bugfix). You command, the agent runs the protected sequence with 1 human OK before the push, and closes with the feature handoff.
---

# /release — Protected release pipeline to production

You trigger: `/release <description of what to release>` (e.g. `/release fix for the "I have a
question" button`). The description becomes the base of the commit message + changelog entry.

**Autonomy model: 1 OK.** The agent runs ALL the safe/local work by itself (Phase 0 + 1), stops
ONCE for you to approve — showing the exact diff — and finishes (Phases 2–4). You are interrupted
at that single point, or if a safety gate aborts. At the end it updates the **Feature Record**
(Phase 4): a ledger in git + a narrative memory entry + a chat summary (objective · status · done ·
missing · recommendations), with open items split into 🐛 bug fix / ✨ feature improvement.

---

## Configuration

Every concrete command below is a **slot** resolved from `sdd.config.yaml` in the adopting
project. The pipeline's structure is fixed; the commands are yours.

| Slot | What it is | Example |
|---|---|---|
| `{{DEPLOY_CMD}}` | The command that ships artifacts which **do not travel through git** (functions, workers, containers). Empty for projects where git push *is* the deploy. | `mycloud deploy fn <slug>` |
| `{{PROJECT_REF}}` | The remote/project identifier `{{DEPLOY_CMD}}` targets. | `prod-app-01` |
| `{{TEST_CMD}}` | The regression suite for the touched surfaces. | `npm test` · `pytest -q` |
| `{{DRIFT_CHECK_CMD}}` | Checks that everything running in the target environment has a matching commit (see drift rule below). Exit 1 = drift → ABORT. | `scripts/audit-drift.sh` |
| `{{LANDMINES_CMD}}` | Deterministic scan of the release diff for known historical landmines. Default: `bash scripts/release-landmines.sh`. | `bash scripts/release-landmines.sh` |
| `{{CHANGELOG_HOOK}}` | The project's changelog/release-notes step (append an entry, notify, sync a page). Empty = no changelog. | `bash scripts/changelog-entry.sh` |

Also configured there: `{{LINT_CMD}}` per touched file type (the interpreter's syntax check) —
referenced as part of the lint step, not as a separate pipeline concept.

> **Deploy topology (fill this in for your project).** Write down, once, which paths ship via git
> push and which ship **only** via `{{DEPLOY_CMD}}`. That split is what makes the classification in
> step 6/G3 possible ("does this diff touch production, or is it a no-op?"). A commit that only
> touches non-deployed paths (docs, `.claude/`) is a **no-op deploy — zero production risk**; a
> commit touching deployed paths is a real ship.

---

## PHASE 0 — Pre-release gate (fast AND catches regressions)

> **Philosophy.** What grep can catch, grep does (instant, deterministic). The expensive tool (the
> LLM) is spent only on what grep CANNOT catch: **contract regressions and business-rule breakage
> in code that already worked**. Everything parallelizable runs in parallel. A pass that does not
> apply to the diff is **skipped** (not "reviewed and nothing found").

0. **Pre-flight.** `/release` runs from a **feature worktree** off `origin/main`, NOT from a
   read-only mirror checkout and never from a frozen long-lived branch. If your setup has a mirror
   checkout, detect it (`git rev-parse --git-dir` == `--git-common-dir` ⇒ primary checkout) and, if
   you are in it, **STOP and report**: "run `/release` from a worktree off origin/main".

Order: **0a deterministic (seconds)** → if it passes, **0b + 0c in parallel** → **0d synthesis**.

### 0a. Deterministic net (scripts, no LLM, ~seconds)

Run all four **in parallel**, over the `origin/main...HEAD` diff:

1. **Landmines:** `{{LANDMINES_CMD}}` — scans the historical landmines (identity comparisons,
   raw JWT handling, disabled auth verification, missing row-level policies, privileged functions
   without an explicit revoke, hardcoded secrets, shared-module fan-out) plus the **drift checks**
   (artifact UNTRACKED = applied out of band without a commit; branch behind `origin/main`).
   **Exit 2 → ABORT.** Exit 1 → record as warnings for the "1 OK".
   *Maintenance: a new landmine learned in production becomes a new rule in the script, not a new
   paragraph in this doc.*
2. **Drift:** `{{DRIFT_CHECK_CMD}}` — anything deployed WITHOUT source in git / an orphan
   migration / shared-module fan-out. **Exit 1 → ABORT.** (This is a pre-push gate, not only a
   post-deploy audit.)
3. **Lint:** the syntax check for each touched file type (`{{LINT_CMD}}`, e.g. `php -l`,
   `node --check`, `python -m py_compile`). Error → **ABORT**.
4. **Verify Gate of the spec (BLOCKING whenever a spec exists):**
   ```bash
   scripts/verify-gate.sh .claude/sdd/features/DEFINE_{FEATURE}.md
   ```
   **Resolve the spec** by feature family (the same `feature_id` as the ledger in 4b): look for the
   `.claude/sdd/features/DEFINE_*.md` matching this release. Application rule:

   | Situation | `/release` action |
   |---|---|
   | Spec exists **with** a `## Verify Gate` block | run it and obey the exit table below |
   | Spec exists **without** the block (exit `64`) | **do NOT abort** — the spec predates the gate. Record it as a **Warning** in 0d ("spec without a gate — acceptance is not executable") and continue. Next time you touch that spec, add the block. |
   | **No spec** (small fix, chore, hotfix) | **skip** and report it in 0d as skipped ("no spec — formal SDD waived"). Never invent a gate. |

   | exit | `/release` action |
   |---|---|
   | `0` | 🟢 green — proceed |
   | `2` | 🔴 **ABORT.** Do not push, do not deploy. Back to `/build` / `/iterate`. |
   | `3` | inconclusive — **resolve first**: a smoke returning 403 → run it from the origin host; a missing tool → run it where the tool exists. Never deploy blind. With **equivalent alternative evidence** it is WAIVABLE — it becomes a FAIL-candidate at step 7 (see 0d). |
   | `4` | `manual-ux` → require the **human receipt** in the build report (who signed + date + checklist ok). Without the receipt, **do not deploy** — it becomes the subject of the "1 OK" (step 7). |
   | `5` | 🛑 **clarification-pending** — the spec still carries an active ambiguity marker. **ABORT and go back to `/define`** (protocol in `fragments/CLARIFY.md`). NON_WAIVABLE: an ambiguous spec is never waived. |
   | `64` | no block → handle per the resolution table above (Warning, does not abort). |

   > The gate is a **precondition of the deploy, not the deploy**. No autonomous loop crosses this
   > point — pushing to the deployment branch and running `{{DEPLOY_CMD}}` is an irreversible human
   > decision (the "1 OK" at step 7).

If 0a aborted, **do not even start** the LLM passes — fix and re-evaluate.

> **🤝 (Optional) second external reviewer — human's call.** Before (or in parallel with) the LLM
> passes, an independent review from a different model vendor over the diff. It complements Phase 0,
> it does not replace it.
> **Contract:** the request and the answer follow
> `.claude/sdd/templates/fragments/ADVISOR_CONSULT.md` (VERDICT · TOP RISKS ≤3 · SPECIFIC FIXES ·
> WHAT TO IGNORE, ≤300 words); every note is **APPLIED or REBUTTED** in the Advisor Ledger of the
> release report — never dropped in silence.
> ⚠️ **Limit:** an external reviewer sees **git state only** — it reviews the *committed* code, but
> it does NOT see what is running in production nor the git↔environment drift. So it **does not
> replace** a real smoke of a migration/function that carries logic (the same reason a typecheck
> does not catch un-executed SQL).

### 0b. Blast radius / regression (LLM — THE PASS THAT CATCHES BREAKAGE IN CODE THAT ALREADY WORKED)

This is the pass that catches the bug that "passes": it is almost never in the diff — it is in the
**unmodified code that depends on what changed**. So do not review the diff in isolation:
**enumerate the surfaces that changed and trace every consumer**.

**Step 1 — enumerate changed surfaces.** From the diff, list everything that has a *contract*:
- an exported function / shared helper whose **signature or return shape** changed;
- an **endpoint** whose response body (JSON) changed shape;
- a **stored procedure / SQL function** whose signature, returned columns or semantics changed;
- a **table column** renamed / removed / re-typed (migration);
- a **global** exposed to the frontend (injected config object, `window.*`);
- a **template tag / hook / permission gate** in the view layer.

**Step 2 — for EACH surface, dispatch a focused sub-agent IN PARALLEL** (one per surface —
parallel = fast). Each agent gets the instruction:

> Surface X changed from `<BEFORE>` to `<AFTER>` (compare against
> `git show origin/main:<file>`). Find ALL consumers (`grep -rn` for the function/endpoint/column/
> global name across frontend, backend and SQL) and, for each one, decide: **is the consumer still
> correct under the new contract?** Focus on: a return shape that flipped array↔object, a renamed
> field the caller still reads, `.length`/`.map` over something that stopped being an array, an
> endpoint whose frontend expects a field that disappeared, a column a query still references, a
> permission gate that now blocks someone who used to pass. Return ONLY the BROKEN consumers, with
> `file:line` and why. If none, return "OK".

**Step 3 — business invariants of the touched module.** Before closing, cross-check the modified
area against the recorded invariants (the module's own guidance file + your project memory). The
kind of invariant that grep never catches:
- *the same score is computed in two stored procedures that must stay identical* — one changed
  without the other? → **regression**.
- *a hard-coded scope threshold* — did the cut-off move? verify the rule.
- *a new action on one surface must exist on BOTH surfaces that render it*.
- *a tab belongs to exactly ONE group* (1:1 mapping).
If the diff touches a module with a known invariant, **state explicitly** that the invariant was
preserved (or flag the violation).

**Step 4 — regression tests (deterministic, gated by a baseline).**
Run `{{TEST_CMD}}` scoped to the touched surfaces. Compare today's red against a committed
baseline of already-red tests (bitrot: incomplete mocks, stale fixtures — **not** production bugs):
- **a NEW failure = a business rule broken by this release** → **ABORT**;
- no new failure (only baseline reds) → proceed;
- the test runner is absent → warn and fall back to the LLM blast-radius pass (never block delivery
  for a missing tool — same rule as verify-gate exit 3).
When you fix a bitrotted test, remove its line from the baseline (it starts guarding production).

### 0c. Security (LLM — ONLY if the diff has an auth/data surface)

**Skip entirely** if the diff touches no backend function, no migration and no permission gate.
Otherwise, focus on the vectors `{{LANDMINES_CMD}}` does NOT cover (the greppable ones already ran
in 0a):
- the **caller-identity function** (`auth.uid()` and equivalents) called from a **privileged/service
  context** → NULL → bypasses every gate (an unprotected feature with no visible error) → **CRITICAL**.
- **auth verification disabled** on an endpoint + a gate that reads the token but never **validates**
  it against the auth provider → an expired/forged token passes → **CRITICAL**.
- sensitive internal scoring/notes fields leaving a query without an explicit whitelist.
- `console.log` / logger printing raw bodies, transcripts or PII → visible in log retrieval →
  **Warning**.
- a row-level policy calling the identity function in a direct subquery (instead of via a
  privileged helper) → privilege escalation.

### 0d. Gate synthesis — VERDICT

Classify each **CRITICAL** finding using the waivability table (the abort logic did not change —
it just got a name and three enumerated exceptions):

| Class | Findings | Effect |
|---|---|---|
| **NON_WAIVABLE** | critical security vector · drift (exit 1) · lint failure · orphan migration · a broken consumer in the blast radius · a violated invariant · Verify Gate exit **2** (red) or **5** (clarification pending) | **ABORT here**, report with `file:line` and stop. Do not commit. Never reaches step 7. |
| **WAIVABLE** (closed list — 3 classes) | Verify Gate exit **3** (inconclusive) **with equivalent alternative evidence presented** · a red test **provably pre-existing in the baseline** (not introduced by this diff) · a pending manual-ux receipt **when the deploy changes no visual surface** | **Does not abort** — becomes a **FAIL-candidate**, presented at step 7 for a human decision: fix it (aborts) or WAIVED with a record. |

Emit **exactly one verdict** and report it in the synthesis:

| Verdict | When |
|---|---|
| 🟢 **PASS** | zero findings (Info only) |
| 🟡 **CONCERNS** | zero criticals + ≥1 Warning → **each warning becomes a 🐛/✨ open item in the Record** (Phase 4) |
| 🔴 **FAIL** | ≥1 NON_WAIVABLE (aborts here) OR a FAIL-candidate the human chose to fix |
| ⚪ **WAIVED** | only a WAIVABLE FAIL-candidate, waived by **the human at step 7**, with a structured record: `WAIVED · class=<from the table> · finding=<one line> · reason=<one line> · by=<human> · date=YYYY-MM-DD` |

> **The agent NEVER emits WAIVED.** It is a state created by an explicit human decision inside the
> 1 OK. Without a `reason=`, the candidate stays FAIL and aborts. The verdict (and the WAIVED
> record, if any) goes into the **Feature Record** in Phase 4 (field `Release verdict:`).

- Also report what was **skipped** (e.g. "0c security skipped — the diff only touches docs";
  "tests not run — runner absent"; "**Verify Gate skipped — no spec**" or "**spec without a gate
  block**") so as not to create a false sense of full coverage.

---

## PHASE 1 — Autonomous (no questions; abort only if a gate fails)

1. **Scope.** `git status --short`. List the files belonging to THIS release (related to the
   description). Classify each per the deploy topology: ships via git push · ships via
   `{{DEPLOY_CMD}}` · does not deploy (docs/`.claude/`). **Ignore WIP from other features** in the
   working tree — the same machine may run several simultaneous SDD sessions.

2. **Lint.** Already covered in 0a.3. If Phase 0 passed, proceed.

3. **Version bump** (only if a versioned artifact changed). Bump the version constant/manifest of
   the deployed package. Patch for a fix, minor for a feature.
   **Version collision (parallel sessions):** the definitive bump is computed from the version on
   `origin/main` (in the fresh worktree from step 5), **not** from the local branch (which may be
   behind). If another session already took your number, skip to the next free one.

4. **Atomic commit.** `git add <the SPECIFIC files of this release>` — **NEVER `git add -A` / `-u`**
   (it drags WIP from other sessions). Commit with a message derived from the description.
   Verify via `git diff --cached --name-only` that only the expected files are staged.

   **4b. Release ledger (immutable record — goes INSIDE the atomic commit).**
   Before committing, resolve the feature family (search your project memory + `ls
   .claude/sdd/releases/` + the SDD artifact name) and create:
   ```
   .claude/sdd/releases/<feature_id>/<slice_id>_<version-or-date>.yaml
   ```
   with `feature_id`, `slice_id`, `version` (if bumped), `state`
   (`shipped` | `partial` | `paused`), `dod` (what "feature complete" means) and `description`
   (one line). **No SHA inside the file** (it is derivable from git itself).
   A NEW file per release = append-only by construction, zero conflicts between parallel sessions,
   and a deterministic portfolio source **in git** (narrative memory lives outside git — the ledger
   is the record that survives). The Feature Record (Phase 4) is a narrative projection of this.

5. **Land on the deployment branch via an isolated worktree.** Never push the divergent local
   branch. `git fetch origin main` → `git worktree add /tmp/release-<slug> origin/main` →
   `git cherry-pick <commit sha>`.

   **5b. Cherry-pick conflict → try a patch-apply of the increment BEFORE aborting.**
   A cherry-pick conflicts when the local branch is stale (a worktree continuing a feature that was
   **already shipped**: the "ahead" commit is a duplicate-by-content of one already on the
   deployment branch with a different SHA; OR the branch has a newer version of a file you edited →
   copying the whole file REGRESSES that fix). Instead of aborting blind, land **only the increment**:
   - `git cherry-pick --abort` in the `/tmp` worktree.
   - Per file, see what the branch already moved ahead: `git diff --quiet origin/main HEAD -- <f>`
     (exit 0 = identical, clean transplant; exit 1 = the branch changed that file → inspect).
   - Generate a patch of only your changes and dry-run it in the fresh worktree:
     `git -C <your-worktree> diff <base>..HEAD -- <files> > /tmp/inc.patch` →
     `git -C /tmp/release-<slug> apply --check /tmp/inc.patch`.
   - It applies cleanly when your hunks sit in different regions from what the branch changed
     (preserving the branch's fixes). `git apply` + commit. An **additive idempotent migration**
     (`ADD COLUMN IF NOT EXISTS`) applies cleanly regardless of timestamp ordering.
   - **Only ABORT** if not even the patch-apply is clean (a real hunk overlap): show the conflict,
     do not resolve it blind (it may be another session's work).

6. **Pre-push gates** (in the worktree):
   - **G1:** `git diff origin/main..HEAD --name-only` = only the expected files. An unexpected file
     (especially a deployed path you did not plan, or a memory/state directory) → ABORT.
   - **G2:** no deletion of an artifact that is deployed and LIVE (cross-check with
     `{{DRIFT_CHECK_CMD}}` if the diff deletes anything under a deployed path).
   - **G3:** classify the diff — does it touch a deployed path (real ship) or only non-deployed
     paths (no-op)?

7. **STOP and show (the 1 OK):** present `git diff origin/main..HEAD --stat`, the classification
   (does it ship? does it need `{{DEPLOY_CMD}}`? is it a no-op?), what each thing does in
   production, the **Verify Gate state (0a.4)** — green / skipped-no-spec / spec-without-block, or
   the human receipt if `manual-ux`, the **VERDICT from 0d** (PASS / CONCERNS with the list of
   warnings→open items / or the **WAIVABLE FAIL-candidates**, each with its class + evidence — for
   each candidate, ask inside this same OK: **fix** (aborts and returns to build) or **WAIVED**?
   WAIVED requires the human's one-line `reason=` here, otherwise it stays FAIL and aborts), the
   summary of Phase 0 findings that did not abort (if none, confirm "✅ no critical findings"), and
   the **`feature_id` of the ledger (4b)** — if family resolution was ambiguous ("is this a slice of
   an existing record or a new feature?"), this is the moment to confirm it, inside this same OK
   (never an extra stop).
   Ask: **"May I finish (push + deploy + verify)?"**

---

## PHASE 2 — After the "go"

8. **Push `HEAD:main`.** Re-check the base immediately before: `git fetch origin main` +
   `git merge-base --is-ancestor origin/main HEAD` (exit 0 = fast-forward; exit 1 = the base moved
   during validation → recreate the worktree from a fresh `origin/main`, re-land and re-check).
   **NEVER `--force`.** `git push origin HEAD:main`.

9. **Out-of-band deploy** (only if a path that does not travel through git changed):
   - `{{DEPLOY_CMD}} <artifacts> --project {{PROJECT_REF}}`.
   - If a **shared module** changed: redeploy EVERY importer
     (`grep -rln "<shared/module>" <source root>`) — a shared module does not deploy itself into
     the artifacts that already bundled it.
   - Migrations: apply, and make sure the paired `.sql` file is committed (drift rule below).
   - **Drift rule: deploying without committing the source is forbidden.** The commit already
     happened in Phase 1.

10. **Verify:**
    - Run your project's post-deploy verification (CI run status, health check, canary), configured
      as `{{DEPLOY_CMD}}`'s companion check in `sdd.config.yaml`. A known transient failure →
      re-run before treating it as red.
    - Drift: `{{DRIFT_CHECK_CMD}}` → exit 0 (no critical drift).

11. **Changelog.** Run `{{CHANGELOG_HOOK}}` (skip if the project has none). Commit + push.
    ⚠️ **SIZE: keep the entry SHORT — max ~600 characters (2–4 lines).** The rich detail (root
    cause, files, decisions, deploy) lives in the ledger `.claude/sdd/releases/<feature>/` and in
    the build report — not in the changelog. **Why:** paragraph-sized entries once grew a changelog
    to several megabytes; because it lived inside an auto-loaded guidance file, it
    blew up the context window of every new session. Keep changelogs out of auto-loaded files, and
    consider a pre-commit hook that blocks any auto-loaded file over 100 KB.
    ⚠️ **If anything parses the changelog** (a release-notes page, a bot), the first line has a
    **canonical syntax** — document it in `sdd.config.yaml` and follow it exactly; a format drift
    silently freezes the consumer. Prefer a CI check that fails loudly when a NEW entry does not
    parse.
    **Changelog conflict (the base moved):** `git checkout --ours CHANGELOG.md` (takes the complete
    upstream file, including other sessions' entries) and **prepend** your entry at the top —
    **NEVER `--theirs`** (it drops the new upstream entries).

12. **Ship cleanup.** `git worktree remove /tmp/release-<slug> --force` (the temporary push worktree).

---

## PHASE 3 — Git hygiene (stay current and clean)

Goal: once the feature is in production, leave no branch/worktree/WIP dangling.

13. **Sync + prune.** `git fetch origin main` · `git worktree prune` (drops refs of dead worktrees).
14. **Branches already in production.** `git branch --merged origin/main | grep -vE '^\*|(^| )main$'`
    → whatever remains is already on the deployment branch; offer to delete it (`git branch -d <branch>`).
15. **This feature's dev worktree.** The feature is in production, so the worktree is disposable.
    **If `/release` is running FROM INSIDE that worktree**, it cannot remove itself — so REPORT to
    the user: *"Feature in production. To clean up: close this editor window and run, from the main
    repo: `git worktree remove <worktree path> --force && git branch -D <branch>`"*. If the user
    asks you to do it, run it via `git -C "<main repo>"` (cwd outside the worktree).

15b. **Archive the SDD artifacts — ONLY if this release closed the feature's DoD** (if the feature
    is still open, SKIP — later slices still read these files). Move (do not copy — `git mv`, which
    avoids duplicates) the family's artifacts:
    ```bash
    mkdir -p .claude/sdd/archive/{FEATURE}/
    git mv .claude/sdd/features/DEFINE_{FEATURE}.md      .claude/sdd/archive/{FEATURE}/
    git mv .claude/sdd/features/DESIGN_{FEATURE}.md      .claude/sdd/archive/{FEATURE}/
    git mv .claude/sdd/reports/BUILD_REPORT_{FEATURE}.md .claude/sdd/archive/{FEATURE}/
    git mv .claude/sdd/reviews/UX_REVIEW_{FEATURE}.md    .claude/sdd/archive/{FEATURE}/  # if it exists
    ```
    Commit it together with the changelog (step 11) or as its own commit — it is `.claude/`, a
    **no-op deploy**.
    ⚠️ **No extra "SHIPPED" narrative file.** The record of what shipped is already the **YAML
    ledger** (4b, in git, append-only) + the **Feature Record** (Phase 4) + the **tombstone line**
    (step 19). Creating a third narrative artifact is exactly the duplication this pipeline removed.
    ⚠️ **Do not sweep the historical backlog.** This step applies **from the current feature
    forward**. A retroactive cleanup is a separate, deliberate operation — part of those old files
    still belong to active features.

15c. **Permission-allowlist harvest.** If your harness supports harvesting repeated read-only tool
    calls into a versioned allowlist, invoke it NOW — the end of a feature is when this session's
    transcript is full of the repeated read-only patterns (the start of a session in a fresh
    worktree means an empty transcript and a null harvest). If there is a delta: its own commit +
    push (a **no-op deploy**) → the next worktrees start with fewer permission prompts. No delta →
    report "allowlist already saturated" and move on.
    ⛔ Accept read-only patterns only; NEVER allowlist an interpreter/shell wildcard
    (`python3 *`, `bash *`) nor any tool that mutates production.

16. **Final report.** Version, commits/SHAs, deploy run, drift status, what went to production,
    whether the SDD artifacts were archived (15b) or why not, and the git state (branches/worktrees
    clean, or the cleanup command left pending for the user).

---

## PHASE 4 — Feature Record (memory + summary + lifecycle)

Goal: **every release updates the Feature Record by construction** — with no dependence on a
question or on discipline (an optional question here is precisely what once produced a lying
portfolio). The deterministic record (ledger 4b) is already in the commit; this phase writes the
narrative layer and closes the lifecycle.

17. **Update the Feature Record (UNCONDITIONAL — do not ask).** Update the feature's record
    (header: Objective · Status · Done · Missing · DoD · Recommendations, plus a slice subsection)
    and the feature's single line in your portfolio index (in place; mark it complete ONLY if the
    whole feature closed its DoD). Use the SAME `feature_id` resolved in 4b. Slice content:
    - **What shipped:** version, commit SHA(s), artifacts deployed, deploy run.
    - **Release verdict (0d):** `PASS` / `CONCERNS` / `WAIVED` with the date. If WAIVED, paste the
      full structured record (`class= · finding= · reason= · by= · date=`) — it is the audit trail
      of "consciously waived vs. forgotten".
    - **Classified open items** — split explicitly into:
      - 🐛 **bug fix** — something left broken/partial, an accepted known regression, an untreated
        edge case;
      - ✨ **feature improvement** — a planned increment, a later slice, hardening, UX, scope follow-up.
    - **Phase 0 warnings that did not abort** (0a exit 1, accepted 0b/0c findings) go here as
      follow-ups — a known risk must not evaporate between sessions.
    - **Ordered next steps** with exact IDs/commands (self-contained).
    - **Alerts** (what NOT to touch) + the worktree/git state from Phase 3.
    - A scope change or pause detected during the ship → a line in the record's `## Events`
      (never silently overwrite "Missing").
    If the feature left NO follow-up, record that explicitly — a short "shipped, nothing pending"
    record still documents the ship.

18. **Print the Record in the chat (release closing).** Reproduce the updated "📋 Feature Record"
    section — objective · status · done · missing · recommendations — as the last block of the
    report. It is the executive summary of the feature's state after this ship.

19. **Lifecycle ✅ → tombstone.** If the Status became **✅ complete** (DoD objectively satisfied),
    offer the consolidation RIGHT THEN: a summary (with any "PENDING" caveats) as a tombstone line
    in your shipped-features index + deletion of the record and its portfolio line. With 1 OK;
    NEVER delete without confirmation. If refused, a session-start hook should keep nagging in the
    next sessions.
    **Same trigger as step 15b** (archiving the SDD artifacts): DoD closed = tombstone in memory +
    artifacts in `archive/`. If one runs and the other does not, the feature stays half-closed.

20. **Next-session prompt (the only optional step).** If there is an obvious continuation
    (Missing ≠ empty), ask: "Shall I generate the ready-made prompt for the next session?" — if
    yes, produce a self-contained handoff prompt. If the feature closed, skip without asking.

---

## ABORT gates (stop and report, NEVER push)

**Phase 0 — pre-flight:** running from a read-only mirror checkout.

**Phase 0a — deterministic:** `{{LANDMINES_CMD}}` exit 2 · `{{DRIFT_CHECK_CMD}}` exit 1
(un-committed deployed source) · lint failed · **Verify Gate exit 2** (red) · exit 3 unresolved ·
exit 4 (`manual-ux`) without a human receipt in the build report · **exit 5**
(clarification-pending → back to `/define`, never treated as an ordinary red).

**Phase 0b — blast radius / regression (the pass that catches breakage in code that already
worked):** an unmodified consumer broken by the new contract (return shape, renamed field, a
removed column a query still reads, an endpoint whose frontend expects a vanished field, a gate
that now blocks someone who used to pass) · **a violated business invariant** · a test sitting next
to the touched module went red (not in the baseline).

**Phase 0c — security:** the identity function called from a privileged/service context · auth
verification disabled without validating the token · a privileged function without an explicit
revoke · a new table without row-level policies · a hardcoded secret · sensitive fields/PII leaking
through a query.

**Phase 1:** an unexpected file in the diff · both the cherry-pick AND the patch-apply (5b)
conflicted (real hunk overlap) · the deployment branch's base moved during validation ·
`{{DRIFT_CHECK_CMD}}` exit 1 · any write to production without committed source.

---

## When to skip formal SDD

A small fix (few files, a clear decision) may skip BRAINSTORM/DEFINE/DESIGN, but the 0–20 sequence
and the drift rules always apply. A large/ambiguous feature → run `/brainstorm` → `/define` →
`/design` → `/build` FIRST, and `/release` is the final ship step.

---

## References

| Resource | Path |
|---|---|
| Verify Gate (contract + exit codes) | `scripts/verify-gate.sh` · `.claude/sdd/templates/fragments/VERIFY_GATE.md` |
| Clarification protocol (exit 5) | `.claude/sdd/templates/fragments/CLARIFY.md` |
| External review contract | `.claude/sdd/templates/fragments/ADVISOR_CONSULT.md` |
| Landmine scanner (extend it per incident) | `scripts/release-landmines.sh` |
| Slot values | `sdd.config.yaml` |

# BUILD REPORT: {Feature Name}

> Implementation report for {Feature Name}

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Date** | {YYYY-MM-DD} |
| **Author** | build-agent |
| **DEFINE** | [DEFINE_{FEATURE}.md](../features/DEFINE_{FEATURE}.md) |
| **DESIGN** | [DESIGN_{FEATURE}.md](../features/DESIGN_{FEATURE}.md) |
| **Status** | In Progress / Complete / Blocked |

---

## Summary

| Metric | Value |
|--------|-------|
| **Tasks Completed** | {X}/{Y} |
| **Files Created** | {N} |
| **Lines of Code** | {N} |
| **Build Time** | {Duration} |
| **Tests Passing** | {X}/{Y} |
| **Agents Used** | {N} |

---

## Task Execution with Agent Attribution

| # | Task | Agent | Status | Duration | Notes |
|---|------|-------|--------|----------|-------|
| 1 | {Task description} | @{agent-name} | ✅ Complete | {Xm} | {Any notes} |
| 2 | {Task description} | @{agent-name} | ✅ Complete | {Xm} | {Any notes} |
| 3 | {Task description} | (direct) | 🔄 In Progress | - | {No specialist matched} |
| 4 | {Task description} | @{agent-name} | ⏳ Pending | - | - |

**Legend:** ✅ Complete | 🔄 In Progress | ⏳ Pending | ❌ Blocked

**Agent Key:**
- `@{agent-name}` = Delegated to specialist agent via Task tool
- `(direct)` = Built directly by build-agent (no specialist matched)

---

## Agent Contributions

| Agent | Files | Specialization Applied |
|-------|-------|------------------------|
| @{agent-1} | {N} | {What patterns/KB used} |
| @{agent-2} | {N} | {What patterns/KB used} |
| (direct) | {N} | DESIGN patterns only |

---

## Files Created

| File | Lines | Agent | Verified | Notes |
| ---- | ----- | ----- | -------- | ----- |
| `{path/to/file1.py}` | {N} | @{agent-name} | ✅ | {Any notes} |
| `{path/to/file2.py}` | {N} | @{agent-name} | ✅ | {Any notes} |
| `{path/to/config.yaml}` | {N} | (direct) | ✅ | {Any notes} |

---

## Verification Results

### Lint Check (ruff)

```text
{Output from ruff check or "All checks passed"}
```

**Status:** ✅ Pass / ❌ Fail

### Type Check (mypy)

```text
{Output from mypy or "All checks passed" or "N/A - not configured"}
```

**Status:** ✅ Pass / ❌ Fail / ⏭️ Skipped

### Tests (pytest)

```text
{Output from pytest or summary}
```

| Test | Result |
|------|--------|
| `test_function_1` | ✅ Pass |
| `test_function_2` | ✅ Pass |
| `test_integration` | ✅ Pass |

**Status:** ✅ {X}/{Y} Pass | ❌ {N} Fail

---

## Advisor Ledger (conditional — only if an advisor / external review was consulted)

> Contract: `fragments/ADVISOR_CONSULT.md`. Every advisor note is **APPLIED or REBUTTED**
> in writing — never dropped in silence. If there was no consultation, remove this section.

**Consultation:** {type: plan-review | delivery-review | conflict | judgment call} · {date} · {tool}
**Advisor VERDICT:** {1 line, verbatim}

| # | Note | Severity | Decision | Evidence |
|---|------|----------|----------|----------|
| 1 | {1-line summary} | HIGH | APPLIED | commit `{sha}` |
| 2 | {1-line summary} | LOW | REBUTTED | {reason, 1 line} |

---

## Issues Encountered

| # | Issue | Resolution | Time Impact |
|---|-------|------------|-------------|
| 1 | {Description of issue} | {How it was resolved} | {+Xm} |
| 2 | {Description of issue} | {How it was resolved} | {+Xm} |

---

## Deviations from Design

| Deviation | Reason | Impact |
|-----------|--------|--------|
| {What changed from DESIGN} | {Why it changed} | {Effect on system} |

---

## Blockers (if any)

| Blocker | Required Action | Owner |
|---------|-----------------|-------|
| {Description} | {What needs to happen} | {Who can unblock} |

---

## Acceptance Test Verification

| ID | Scenario | Status | Evidence |
|----|----------|--------|----------|
| AT-001 | {From DEFINE} | ✅ Pass / ❌ Fail | {How verified} |
| AT-002 | {From DEFINE} | ✅ Pass / ❌ Fail | {How verified} |
| AT-003 | {From DEFINE} | ✅ Pass / ❌ Fail | {How verified} |

---

## Performance Notes

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| {Metric 1} | {From DEFINE} | {Measured} | ✅ / ❌ |
| {Metric 2} | {From DEFINE} | {Measured} | ✅ / ❌ |

---

## Final Status

### Overall: {✅ COMPLETE / 🔄 IN PROGRESS / ❌ BLOCKED}

**Completion Checklist:**

- [ ] All tasks from manifest completed
- [ ] All verification checks pass
- [ ] All tests pass
- [ ] No blocking issues
- [ ] Acceptance tests verified
- [ ] Ready for /release

---

## Next Step

**If Complete:** `/release <description of what to ship>`

**If Blocked:** Resolve blockers, then `/build` to resume

**If Issues Found:** `/iterate DESIGN_{FEATURE}.md "{change needed}"`

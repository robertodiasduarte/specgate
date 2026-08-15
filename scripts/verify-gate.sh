#!/usr/bin/env bash
# verify-gate.sh — runs a spec's "Verify Gate" as an EXECUTABLE acceptance gate (pass/fail).
#
# This is the core of SpecGate: acceptance stops being prose and becomes a COMMAND that
# /build and /release run and treat as blocking. A loop without an executable stop
# condition produces garbage at scale — this is that stop condition.
#
# The spec carries a fenced ```yaml block under a `## Verify Gate` heading with the keys:
#   kind            test | smoke | eval | typecheck | manual-ux
#   cmd             executable command  (OR "N/A (manual-ux)")
#   pass_when       objective criterion (exit 0 | exit N | contains: TEXT)
#   threshold       eval only           (e.g. "recall >= 0.80")  — informational here
#   manual_fallback manual-ux only      (human checklist)
#
# Usage:
#   scripts/verify-gate.sh <SPEC.md>          # run the gate
#   scripts/verify-gate.sh --print <SPEC.md>  # extract and show the block only (never runs)
#
# Exit codes (the contract every caller must honour):
#   0  = GREEN (passed)                     → /build and /release proceed
#   2  = RED (failed)                       → /build and /release ABORT
#   3  = inconclusive (missing tool, or infra noise such as a 403 from a WAF vs. the
#        runner's IP)                       → caller decides; never counts as red
#   4  = manual-ux: requires a HUMAN SIGNATURE (never auto-passes)
#   5  = clarification-pending: the spec still carries an active ambiguity marker
#        → STOP and go back to the spec phase. This is NOT a red build gate: loops and
#          drivers must never iterate on the design because of it.
#   64 = usage error / missing or malformed block → the spec has no valid gate
#
# Noise filter: a smoke test that receives a 403 from a WAF because of the runner's IP is
# NOT a regression. When kind=smoke and the output contains 403 while something else was
# expected, the gate returns 3 (inconclusive) with instructions to run it from the origin
# host — never 2 (a false red).

set -uo pipefail

PRINT_ONLY=0
if [[ "${1:-}" == "--print" ]]; then PRINT_ONLY=1; shift; fi

SPEC="${1:-}"
if [[ -z "$SPEC" || ! -f "$SPEC" ]]; then
  echo "❌ usage: scripts/verify-gate.sh [--print] <SPEC.md>" >&2
  echo "   (file not found: '${SPEC:-<empty>}')" >&2
  exit 64
fi

# Resolve the spec to an absolute path BEFORE changing directory: commands in the gate are
# meant to run from the repository root, but the spec may have been given as a path relative
# to the caller's cwd. Resolving afterwards silently breaks whenever the two differ.
SPEC="$(cd "$(dirname "$SPEC")" && pwd -P)/$(basename "$SPEC")"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repository" >&2; exit 64; }
cd "$REPO_ROOT" || exit 64

# ---- pending clarification: a spec with an OPEN question does not run its gate (exit 5) ----
# Canonical active form: bracket + "NEEDS CLARIFICATION" + colon (see fragments/CLARIFY.md).
# Documentation mentions live inside code fences or drop the brackets — the scan strips
# fenced blocks before grepping. --print is exempt (authoring aid while writing the spec).
# exit 5 = clarification-pending: its own state; NEVER 2 (loops would iterate on the design)
# and never 64 (that would demote it to a warning).
if [[ $PRINT_ONLY -eq 0 ]]; then
  # Real file line numbers (not the filtered stream); indented fences count too.
  # The fence matcher must also accept a fence nested in a blockquote (`> ```­`), which is how
  # templates present the instructional example. Without the optional `>`, the flag never
  # toggles and the documentation mention is read as an active marker — which would make the
  # shipped template block every new spec.
  PENDING="$(awk '/^[[:space:]]*>?[[:space:]]*```/{f=!f;next} !f{print NR": "$0}' "$SPEC" | grep '\[NEEDS CLARIFICATION:' || true)"
  if [[ -n "$PENDING" ]]; then
    echo "🛑 CLARIFICATION PENDING (exit 5) — '$SPEC' has active ambiguity marker(s):" >&2
    printf '%s\n' "$PENDING" | sed 's/^/   │ /' >&2
    echo "   Resolve them via the protocol (.claude/sdd/templates/fragments/CLARIFY.md): ≤5 questions," >&2
    echo "   answers integrated INTO THE BODY of the spec, logged under '## Clarifications'." >&2
    echo "   Callers must STOP and return to the spec phase — this is NOT a red build gate." >&2
    exit 5
  fi
fi

# ---- extract the fenced ```yaml block following '## Verify Gate' --------------------
# Take from the '## Verify Gate' line up to the next '## ' (next section), then isolate
# the first ``` ... ``` block inside it.
BLOCK="$(awk '
  /^##[[:space:]]+Verify Gate/ { insec=1; next }
  insec && /^##[[:space:]]/    { insec=0 }
  insec                        { print }
' "$SPEC" | awk '
  /^```/ { fence = !fence; if (fence) next; else exit }
  fence  { print }
')"

if [[ -z "${BLOCK// }" ]]; then
  echo "❌ '$SPEC' has no '## Verify Gate' section with a fenced ```yaml … ``` block." >&2
  echo "   Every spec needs the gate (see .claude/sdd/templates/fragments/VERIFY_GATE.md)." >&2
  exit 64
fi

# ---- helper: read a key's value (first occurrence), strip quotes and spaces -------
field() {
  printf '%s\n' "$BLOCK" \
    | grep -E "^[[:space:]]*$1:" \
    | head -1 \
    | sed -E "s/^[[:space:]]*$1:[[:space:]]*//; s/^\"//; s/\"$//; s/[[:space:]]+$//"
}

KIND="$(field kind)"
CMD="$(field cmd)"
PASS_WHEN="$(field pass_when)"
THRESHOLD="$(field threshold)"

if [[ $PRINT_ONLY -eq 1 ]]; then
  echo "── Verify Gate of $SPEC ──"
  echo "kind:       ${KIND:-<empty>}"
  echo "cmd:        ${CMD:-<empty>}"
  echo "pass_when:  ${PASS_WHEN:-<empty>}"
  echo "threshold:  ${THRESHOLD:-—}"
  exit 0
fi

if [[ -z "$KIND" ]]; then
  echo "❌ Verify Gate without 'kind' in '$SPEC'." >&2
  exit 64
fi

case "$KIND" in
  test|smoke|eval|typecheck|manual-ux) ;;
  *) echo "❌ invalid kind: '$KIND' (use test|smoke|eval|typecheck|manual-ux)" >&2; exit 64 ;;
esac

# ---- manual-ux: never auto-passes; it is an explicit human gate --------------------
if [[ "$KIND" == "manual-ux" ]]; then
  echo "🧑‍🎨 Verify Gate kind=manual-ux — requires a HUMAN SIGNATURE (not automatable)."
  echo "   The manual_fallback checklist must be walked through and signed in the build report."
  echo "   /build shows the checklist; /release only passes with the human receipt recorded."
  exit 4
fi

if [[ -z "$CMD" || "$CMD" == "N/A"* ]]; then
  echo "❌ kind=$KIND requires an executable 'cmd' (got: '${CMD:-<empty>}')." >&2
  exit 64
fi

# ---- run the command ---------------------------------------------------------------
echo "▶ Verify Gate [$KIND]: $CMD"
OUT="$(bash -c "$CMD" 2>&1)"
RC=$?
printf '%s\n' "$OUT" | sed 's/^/   │ /'

# ---- infra noise filter: smoke + 403 from WAF vs. runner IP ------------------------
if [[ "$KIND" == "smoke" ]] && printf '%s' "$OUT" | grep -qE '\b403\b'; then
  if ! printf '%s' "$PASS_WHEN" | grep -qiE '403'; then
    echo "⚠️  smoke got a 403 and 403 was NOT the expectation → likely WAF vs. runner-IP noise, NOT a regression."
    echo "    Run the smoke FROM THE ORIGIN host (public egress = 200/401; runner loopback = 403)."
    echo "    Gate INCONCLUSIVE (exit 3) — caller decides; does not count as red."
    exit 3
  fi
fi

# ---- missing tool (test runner, curl, etc.) = inconclusive, not red ----------------
if [[ $RC -eq 127 ]] || printf '%s' "$OUT" | grep -qiE 'command not found|: not found'; then
  echo "⚠️  tool missing while running the gate (rc=$RC) — INCONCLUSIVE (exit 3); delivery is not blocked by a missing tool."
  exit 3
fi
# A delegated test gate already returns 3 when its runtime is absent — propagate it.
if [[ $RC -eq 3 ]] && printf '%s' "$CMD" | grep -q 'test-gate'; then
  echo "⚠️  test runtime missing (delegated gate) — INCONCLUSIVE (exit 3)."
  exit 3
fi
# A smoke that DECLARES itself inconclusive (rc=3 + 'INCONCLUSIVE' in the output — e.g. a
# database URL absent on the runner) propagates exit 3 instead of becoming a false red.
# Caller decides; it never auto-passes.
if [[ $RC -eq 3 ]] && printf '%s' "$OUT" | grep -qi 'INCONCLUSIVE'; then
  echo "⚠️  smoke declared INCONCLUSIVE (rc=3) — propagating exit 3; run it where the connection exists."
  exit 3
fi

# ---- evaluate pass_when --------------------------------------------------------------
PASS_WHEN="${PASS_WHEN:-exit 0}"
ok=0
if [[ "$PASS_WHEN" =~ ^exit[[:space:]]+([0-9]+)$ ]]; then
  want="${BASH_REMATCH[1]}"
  [[ "$RC" -eq "$want" ]] && ok=1
elif [[ "$PASS_WHEN" =~ ^contains:[[:space:]]*(.+)$ ]]; then
  needle="${BASH_REMATCH[1]}"
  printf '%s' "$OUT" | grep -qF "$needle" && ok=1
else
  # default: success == exit 0
  [[ "$RC" -eq 0 ]] && ok=1
fi

if [[ $ok -eq 1 ]]; then
  echo "✅ GATE GREEN ($KIND) — pass_when: '$PASS_WHEN' satisfied (rc=$RC)."
  exit 0
else
  echo "🛑 GATE RED ($KIND) — pass_when: '$PASS_WHEN' NOT satisfied (rc=$RC)." >&2
  echo "   /build and /release must ABORT." >&2
  exit 2
fi

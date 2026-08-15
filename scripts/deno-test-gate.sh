#!/usr/bin/env bash
# deno-test-gate.sh — runs the test suite and ABORTS only on a NEW failure (regression), not on bitrot.
#
# Mature suites carry a tail of already-red tests (incomplete mocks, mojibake fixtures) recorded in
# scripts/deno-test-baseline.txt. This gate compares the red set of RIGHT NOW against the baseline:
# any red test that is NOT in the baseline = a regression introduced by this release.
#
# Usage:
#   scripts/deno-test-gate.sh <file.test.ts> [more...]   # run the given files
#   scripts/deno-test-gate.sh --touched [BASE_REF]       # auto-detect tests for the touched surfaces
#   scripts/deno-test-gate.sh --all                      # whole suite (CI anti-rot for the baseline)
#
# Exit: 0 = no regression (at most failures already in the baseline) · 2 = NEW failure → /release ABORTS
#       3 = test runner absent (caller decides: fall back to the LLM blast-radius pass, do not block)
#
# In --all mode (CI) it also lists baseline tests that HEALED (went green) — candidates for removal
# from the baseline so it does not become a lie (this never aborts).
#
# Config: TEST_CMD and the source root come from sdd.config.yaml ({{TEST_CMD}}, {{SOURCE_ROOT}}).
# The defaults below match a Deno project; override them via the environment.

set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo" >&2; exit 64; }
cd "$REPO_ROOT" || exit 64

# {{TEST_CMD}} / {{SOURCE_ROOT}} — injected from sdd.config.yaml by the adopting project.
TEST_BIN="${SDD_TEST_BIN:-deno}"
TEST_CMD="${SDD_TEST_CMD:-deno test --allow-all --no-check}"
SOURCE_ROOT="${SDD_SOURCE_ROOT:-src}"

if ! command -v "$TEST_BIN" >/dev/null 2>&1; then
  echo "⚠️  ${TEST_BIN} absent — tests not run. Install it to enable this gate."
  echo "    (gate falls back to the LLM blast-radius pass; a missing tool never blocks the release.)"
  exit 3
fi

BASELINE="scripts/deno-test-baseline.txt"
FUNCS="$SOURCE_ROOT"

# ---- build the list of tests to run ----------------------------------------------
TESTS=()
MODE="${1:-}"
if [[ "$MODE" == "--all" ]]; then
  # whole suite (minus integration) — used in CI so the baseline cannot rot again
  while IFS= read -r t; do
    [[ -f "$t" ]] && TESTS+=("$t")
  done < <(find "$FUNCS" -name '*.test.ts' -not -path '*/tests/integration/*' 2>/dev/null | sort)
elif [[ "$MODE" == "--touched" ]]; then
  BASE_REF="${2:-origin/main}"
  # touched surfaces → tests colocated next to them
  CHANGED="$(git diff --name-only "${BASE_REF}...HEAD" -- "$FUNCS" 2>/dev/null | grep -E '\.ts$' | grep -v '\.test\.ts$' || true)"
  while IFS= read -r src; do
    [[ -z "$src" ]] && continue
    cand="${src%.ts}.test.ts"
    [[ -f "$cand" ]] && TESTS+=("$cand")
  done <<< "$CHANGED"
  # plus the .test.ts files modified directly
  while IFS= read -r t; do
    [[ -f "$t" ]] && TESTS+=("$t")
  done < <(git diff --name-only "${BASE_REF}...HEAD" -- "$FUNCS" 2>/dev/null | grep -E '\.test\.ts$' | grep -v '/tests/integration/' || true)
else
  # Explicit args are a CONTRACT (they come from the DEFINE's Verify Gate): a missing file means a
  # BROKEN gate, not a skip. Without this, a build that omits the promised tests passes "green" by
  # running only what happens to exist.
  for t in "$@"; do
    if [[ ! -f "$t" ]]; then
      echo "❌ test declared in the gate does not exist: $t" >&2
      exit 2
    fi
    TESTS+=("$t")
  done
fi

# dedup
IFS=$'\n' TESTS=($(printf '%s\n' "${TESTS[@]:-}" | sed '/^$/d' | sort -u)); unset IFS

if [[ "${#TESTS[@]}" -eq 0 ]]; then
  echo "ℹ️  no test colocated with the touched surfaces — nothing to run."
  exit 0
fi

echo "═══════════════════════════════════════════════════════════════"
echo " deno-test-gate · ${#TESTS[@]} file(s)"
printf '   %s\n' "${TESTS[@]}"
echo "═══════════════════════════════════════════════════════════════"

# ---- run and extract the red set -------------------------------------------------
OUT="$($TEST_CMD "${TESTS[@]}" 2>&1)"
RUN_RC=$?
RED="$(echo "$OUT" | sed -E 's/\x1b\[[0-9;]*m//g' \
        | awk '/^ FAILURES/{f=1;next} /^ ERRORS/{f=0} f && /=> \.\//{ sub(/ => .*/,""); sub(/^[[:space:]]+/,""); print }' \
        | sort -u)"

BASE_LIST="$(grep -v '^#' "$BASELINE" 2>/dev/null | sed '/^$/d')"

# helper (--all mode): point out baseline entries that healed — candidates to prune from the baseline.
report_healed() {
  [[ "$MODE" != "--all" ]] && return 0
  local healed
  healed="$(comm -23 <(echo "$BASE_LIST" | sort -u) <(echo "${RED:-}" | sort -u))"
  if [[ -n "${healed//[$'\n']}" ]]; then
    echo "───────────────────────────────────────────────────────────────"
    echo "🟢 baseline entries that HEALED (now green) — remove from scripts/deno-test-baseline.txt:"
    echo "$healed" | sed '/^$/d' | sed 's/^/     /'
  fi
}

# A non-zero runner exit with nothing parseable in the FAILURES section is NOT green: the
# runner may have died on a compile error, a bad flag or a crash before producing results.
# Declaring success on an empty parse would turn every runner crash into a false pass.
if [[ $RUN_RC -ne 0 && -z "$RED" ]]; then
  echo "🛑 test runner exited rc=$RUN_RC without a parseable failure section — treating as RED." >&2
  echo "$OUT" | tail -15 | sed 's/^/   │ /' >&2
  exit 2
fi

if [[ -z "$RED" ]]; then
  echo "✅ all tests green."
  report_healed
  exit 0
fi

# ---- diff against the baseline ---------------------------------------------------
NEW_RED=""
while IFS= read -r t; do
  [[ -z "$t" ]] && continue
  if ! grep -qxF "$t" <<< "$BASE_LIST"; then
    NEW_RED+="$t"$'\n'
  fi
done <<< "$RED"

KNOWN="$(comm -12 <(echo "$RED") <(echo "$BASE_LIST" | sort -u) | wc -l | tr -d ' ')"
echo "   red: $(echo "$RED" | wc -l | tr -d ' ') (${KNOWN} already in the baseline)"

if [[ -n "${NEW_RED//[$'\n']}" ]]; then
  echo "───────────────────────────────────────────────────────────────"
  echo "🔴 REGRESSION — test(s) that went red and are NOT in the baseline:"
  echo "$NEW_RED" | sed '/^$/d' | sed 's/^/     /'
  echo "═══════════════════════════════════════════════════════════════"
  echo " ❌ /release must ABORT — the change broke a business rule covered by a test."
  exit 2
fi

echo "✅ no regression (only failures already known in the baseline)."
report_healed
exit 0

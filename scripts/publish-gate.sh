#!/usr/bin/env bash
# publish-gate.sh — the anti-leak gate for the SpecGate public repository.
#
# Runs five checks over a working tree and answers one binary question: is this tree
# safe to publish? Every check is a hard stop — this gate is the last barrier before a
# push that is irreversible in practice (caches, forks, clones).
#
# Usage:
#   scripts/publish-gate.sh [TREE]                       # defaults to $PWD
#   PUBLISH_GATE_MODE=ci scripts/publish-gate.sh          # CI: generic patterns only
#
# Modes:
#   port (default) — run from the source repository during publication. REQUIRES
#                    PUBLISH_GATE_EXTRA_PATTERNS pointing to a readable private pattern
#                    file. Missing it is a FAILURE, never a silent skip: a gate that
#                    quietly drops a layer is worse than no gate at all.
#   ci             — run inside the public repository, which legitimately has no private
#                    layer. Generic patterns only. Never use this mode to publish.
#
# Exit: 0 = green (safe to publish) · non-zero = blocked. There is no "warning" state.

set -uo pipefail

TREE="${1:-$PWD}"
MODE="${PUBLISH_GATE_MODE:-port}"
FAIL=0

[[ -d "$TREE" ]] || { echo "❌ tree not found: $TREE" >&2; exit 64; }
# Absolute from here on: G4 runs verify-gate.sh from inside the tree, and a relative path
# would resolve against the wrong directory once we cd.
TREE="$(cd "$TREE" && pwd -P)"

hr() { printf '─%.0s' {1..66}; echo; }
ok()   { echo "  ✅ $*"; }
bad()  { echo "  ⛔ $*" >&2; FAIL=1; }

echo "publish-gate — tree: $TREE — mode: $MODE"
hr

# ── G1: secrets ────────────────────────────────────────────────────────────────
# gitleaks is mandatory. An absent scanner is not an inconclusive result here: this
# is the only automated barrier against publishing a credential.
echo "G1 secrets (gitleaks)"
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "  ⛔ gitleaks not installed — install it (brew install gitleaks) and re-run." >&2
  echo "     This gate never skips the secret scan." >&2
  exit 1
fi
if gitleaks detect --source "$TREE" --no-git --redact --exit-code 1 >/tmp/gitleaks.$$ 2>&1; then
  ok "no secrets detected"
else
  bad "gitleaks found candidate secrets:"; sed 's/^/     /' /tmp/gitleaks.$$ >&2
fi
rm -f /tmp/gitleaks.$$

# ── G2: forbidden patterns ─────────────────────────────────────────────────────
echo "G2 forbidden patterns"
PATTERN_FILES=("$TREE/scripts/publish-gate-patterns.txt")
if [[ "$MODE" == "port" ]]; then
  if [[ -r "${PUBLISH_GATE_EXTRA_PATTERNS:-}" && -s "${PUBLISH_GATE_EXTRA_PATTERNS:-}" ]]; then
    PATTERN_FILES+=("$PUBLISH_GATE_EXTRA_PATTERNS")
  else
    echo "  ⛔ mode=port requires PUBLISH_GATE_EXTRA_PATTERNS (readable, non-empty)." >&2
    echo "     Refusing to run with a missing private layer. Use mode=ci only inside CI." >&2
    exit 1
  fi
fi
# Docs legitimately contain e-mails on RFC 2606 reserved domains; ERE has no lookahead, so
# that exemption is applied to the hits — and ONLY for e-mail-shaped patterns (the pattern
# contains '@'). Exempting every pattern would let any leak hide by sharing a line with an
# example e-mail.
EXAMPLE_DOMAIN_RE='@example\.(com|org|net)'
# The pattern files themselves would always self-match. Exempt them by EXACT path (never by
# basename: a basename exclusion would also skip a same-named file planted anywhere else).
PATTERN_PATHS_RE="$(for pf in "${PATTERN_FILES[@]}"; do [[ -e "$pf" ]] && realpath "$pf"; done | sed 's/[.[\*^$()+?{|]/\\&/g' | paste -sd'|' -)"
for pf in "${PATTERN_FILES[@]}"; do
  [[ -r "$pf" ]] || { bad "pattern file unreadable: $pf"; continue; }
  while IFS= read -r rx; do
    [[ -z "$rx" || "$rx" == \#* ]] && continue
    hits=$(grep -rInE -i --exclude-dir=.git "$rx" "$TREE" 2>/dev/null)
    rc=$?
    # grep: 0 = match, 1 = no match, >1 = error. An invalid regex must FAIL the gate —
    # treating rc=2 as "no match" would turn a broken pattern into a silent green.
    if [[ $rc -gt 1 ]]; then
      bad "invalid pattern (grep rc=$rc): /$rx/ in $(basename "$pf")"
      continue
    fi
    [[ $rc -eq 0 ]] || continue
    # Drop hits coming from the pattern files themselves (exact absolute path match).
    if [[ -n "$PATTERN_PATHS_RE" ]]; then
      hits=$(while IFS= read -r line; do
        f="${line%%:*}"; [[ -e "$f" ]] && rp="$(realpath "$f")" || rp="$f"
        grep -qE "^($PATTERN_PATHS_RE)$" <<<"$rp" || printf '%s\n' "$line"
      done <<<"$hits")
    fi
    [[ -z "$hits" ]] && continue
    if [[ "$rx" == *@* ]]; then
      # Keep a hit line only if it carries at least one e-mail that is NOT on a reserved
      # example domain. Dropping the whole line on any example.com occurrence would let a
      # real address hide by sharing the line with an example one.
      hits=$(while IFS= read -r line; do
        grep -oE "$rx" <<<"${line#*:*:}" | grep -qvE "$EXAMPLE_DOMAIN_RE" && printf '%s\n' "$line"
      done <<<"$hits")
      [[ -z "$hits" ]] && continue
    fi
    bad "pattern matched: /$rx/"; head -5 <<<"$hits" | sed 's/^/     /' >&2
  done < "$pf"
done
[[ $FAIL -eq 0 ]] && ok "no forbidden pattern matched"

# ── G3: allowlist ──────────────────────────────────────────────────────────────
# Every file in the tree must be declared in MANIFEST.txt. Allowlist, never denylist:
# a file arrives by explicit decision, not by failing to be excluded.
echo "G3 allowlist (MANIFEST.txt)"
MAN="$TREE/MANIFEST.txt"
if [[ ! -r "$MAN" ]]; then
  bad "MANIFEST.txt missing — cannot prove the tree contents were declared"
else
  g3_ok=1
  # Direction 1: every file in the tree is declared (no stowaways).
  while IFS= read -r f; do
    rel="${f#"$TREE"/}"
    grep -qxF "$rel" "$MAN" || { bad "undeclared file: $rel"; g3_ok=0; }
  done < <(find "$TREE" -type f -not -path "*/.git/*" -not -name "MANIFEST.txt")
  # Direction 2: every declared file exists (no silently deleted core file — a future PR
  # removing a command that G4/G5 do not cover must not leave the gate green).
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    [[ -f "$TREE/$rel" ]] || { bad "declared but missing: $rel"; g3_ok=0; }
  done < "$MAN"
  [[ $g3_ok -eq 1 ]] && ok "tree and manifest match in both directions"
fi

# ── G4: verify-gate exit contract ──────────────────────────────────────────────
# The framework's own contract must survive translation. Fixture → expected exit:
#   NEEDS_CLARIFICATION → 5 (an open ambiguity marker halts the pipeline)
#   CLARIFY_RESOLVED / TOKEN_IN_FENCE / CONTROL → 0
echo "G4 verify-gate exit contract"
declare -a FX=(
  "DEFINE_FIXTURE_NEEDS_CLARIFICATION.md:5"
  "DEFINE_FIXTURE_CLARIFY_RESOLVED.md:0"
  "DEFINE_FIXTURE_TOKEN_IN_FENCE.md:0"
  "DEFINE_FIXTURE_CONTROL.md:0"
)
for entry in "${FX[@]}"; do
  fx="${entry%%:*}"; want="${entry##*:}"
  path="$TREE/.claude/sdd/fixtures/$fx"
  [[ -r "$path" ]] || { bad "fixture missing: $fx"; continue; }
  (cd "$TREE" && bash scripts/verify-gate.sh "$path" >/dev/null 2>&1)
  got=$?
  [[ "$got" == "$want" ]] && ok "$fx → exit $got" || bad "$fx → exit $got (expected $want)"
done

# ── G5: documentation completeness ─────────────────────────────────────────────
echo "G5 documentation"
for f in README.md README.pt-BR.md LICENSE NOTICE CONTRIBUTING.md \
         docs/quickstart.md docs/adaptation-guide.md docs/verify-gate-contract.md docs/comparison.md \
         docs/pt-BR/quickstart.md docs/pt-BR/adaptation-guide.md docs/pt-BR/verify-gate-contract.md docs/pt-BR/comparison.md; do
  [[ -r "$TREE/$f" ]] || bad "required doc missing: $f"
done
grep -q "README.pt-BR.md" "$TREE/README.md" 2>/dev/null || bad "README.md does not link its pt-BR counterpart"
grep -q "README.md" "$TREE/README.pt-BR.md" 2>/dev/null || bad "README.pt-BR.md does not link back to README.md"
grep -qi "agentspec" "$TREE/NOTICE" 2>/dev/null || bad "NOTICE lacks the AgentSpec attribution (MIT requires it)"
[[ $FAIL -eq 0 ]] && ok "docs present, cross-linked, attribution in place"

hr
if [[ $FAIL -eq 0 ]]; then
  echo "✅ publish-gate GREEN — tree is publishable (human review of the file list still required)"
  exit 0
fi
echo "⛔ publish-gate BLOCKED — fix the findings above. Never retry silently, never loosen a" >&2
echo "   pattern without adding an equivalent one." >&2
exit 1

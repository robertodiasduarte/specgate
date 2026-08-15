#!/usr/bin/env bash
# release-landmines.sh — deterministic scanner for known landmines in the release diff.
#
# Runs the historical /release checklist as greps, in seconds, with NO LLM. It only looks at
# ADDED LINES (^+) of the base...HEAD diff, so it never flags pre-existing code. This takes the
# bulk of the load off the LLM passes (which stay free for blast-radius / regression reasoning).
#
# Usage:
#   scripts/release-landmines.sh [BASE_REF]      # default BASE_REF=origin/main
#   scripts/release-landmines.sh --working       # use the working tree (HEAD + uncommitted)
#
# Exit codes (/release maps these):
#   0 = clean (INFO at most)
#   1 = WARNING only (record it; it goes into the single "OK" confirmation)
#   2 = CRITICAL    (ABORT the release)
#
# ⚠️  THE RULES BELOW ARE EXAMPLES — they are the EXTENSION POINT for the adopting project.
# This public skeleton ships three generic rules that almost any project wants. The real value of
# this script comes from YOUR rules: every time an incident escapes to production, write the grep
# that would have caught it as a new `crit`/`warn`/`info` rule here. That is the cheap place to
# encode a post-mortem — a rule added here costs milliseconds and never forgets.
#
# Infra-specific values ({{DEPLOY_CMD}}, {{PROJECT_REF}}, {{TEST_CMD}}) come from sdd.config.yaml;
# read them into the variables below rather than hardcoding them.

set -uo pipefail

BASE_REF="origin/main"
MODE="diff"
for arg in "$@"; do
  case "$arg" in
    --working) MODE="working" ;;
    -*) echo "unknown flag: $arg" >&2; exit 64 ;;
    *) BASE_REF="$arg" ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not a git repo" >&2; exit 64; }
cd "$REPO_ROOT" || exit 64

# ---- config injected from sdd.config.yaml ----------------------------------------
# {{PROJECT_REF}} — remote/project identifier used by out-of-band deploys, if any.
# {{DEPLOY_CMD}}  — the command that deploys outside of git (the source of drift rule ① checks).
MIGRATIONS_DIR="${SDD_MIGRATIONS_DIR:-migrations}"

# ---- file and diff collection ----------------------------------------------------
if [[ "$MODE" == "working" ]]; then
  CHANGED_FILES="$(git diff --name-only --diff-filter=d HEAD; git ls-files --others --exclude-standard)"
  diff_added() { git diff HEAD -- "$1" 2>/dev/null | grep '^+' | grep -v '^+++'; cat "$1" 2>/dev/null | sed 's/^/+/' ; }
else
  if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
    echo "base ref '$BASE_REF' does not exist (run git fetch origin main?)" >&2; exit 64
  fi
  CHANGED_FILES="$(git diff --name-only --diff-filter=d "${BASE_REF}...HEAD")"
  diff_added() { git diff "${BASE_REF}...HEAD" -- "$1" 2>/dev/null | grep '^+' | grep -v '^+++'; }
fi

CHANGED_FILES="$(echo "$CHANGED_FILES" | sed '/^$/d' | sort -u)"

if [[ -z "$CHANGED_FILES" ]]; then
  echo "ℹ️  no file changed vs ${BASE_REF} — nothing to scan."
  exit 0
fi

# ---- accumulators ----------------------------------------------------------------
CRIT=0; WARN=0; INFO=0
crit() { printf '🔴 CRITICAL | %s\n             %s\n' "$1" "$2"; CRIT=$((CRIT+1)); }
warn() { printf '🟡 WARNING  | %s\n             %s\n' "$1" "$2"; WARN=$((WARN+1)); }
info() { printf 'ℹ️  INFO     | %s\n             %s\n' "$1" "$2"; INFO=$((INFO+1)); }

# helper: test whether a file matches an extension/path glob
match() { case "$1" in $2) return 0;; *) return 1;; esac; }

echo "═══════════════════════════════════════════════════════════════"
echo " release-landmines · base=${BASE_REF} · $(echo "$CHANGED_FILES" | wc -l | tr -d ' ') file(s)"
echo "═══════════════════════════════════════════════════════════════"

# =================================================================================
# PER-FILE RULES (over ADDED lines)
#
# EXAMPLE RULE ② — a secret literal appears in a tracked file.
# Add your own rules in this loop, following the same shape:
#   if echo "$ADDED" | grep -Eq "<pattern>"; then
#     crit "<one-line what broke>" "$f — <how to fix it>"
#   fi
# =================================================================================
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  ADDED="$(diff_added "$f")"
  [[ -z "$ADDED" ]] && continue

  # ---- ② secret literal committed to a tracked file ------------------------------
  # Provider API keys, bearer/JWT literals and inline `secret = "..."` assignments belong in the
  # environment, never in the tree. A committed secret is already leaked — history keeps it.
  if echo "$ADDED" | grep -Eqi "(sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}|(secret|api[_-]?key|password|token)\s*[:=]\s*['\"][A-Za-z0-9_\-]{12,}['\"])"; then
    crit "possible hardcoded secret in the added lines — read it from the environment instead" \
         "$f — move it to an env var / secret store and rotate the exposed value"
  fi

done <<< "$CHANGED_FILES"

# =================================================================================
# GLOBAL RULES (span the whole repo, not just the diff)
# =================================================================================

# ---- ① migration applied out of band has no matching commit ---------------------
# A migration applied through a console/MCP/dashboard deploys WITHOUT git: the file stays out of
# the commit and the main branch drifts from what actually runs in production. Read-only check.
UNTRACKED_SQL="$(git ls-files --others --exclude-standard -- "${MIGRATIONS_DIR}/*.sql" 2>/dev/null | grep -E '/[0-9]{14}_[^/]+\.sql$' || true)"
if [[ -n "$UNTRACKED_SQL" ]]; then
  while IFS= read -r mig; do
    [[ -z "$mig" ]] && continue
    warn "UNTRACKED migration — it will not reach the commit (applied out of band?)" \
         "$mig — git add + commit, or delete it if it was scratch [drift]"
  done <<< "$UNTRACKED_SQL"
fi

# ---- ③ the working tree is dirty at release time --------------------------------
# Releasing with uncommitted changes ships something no commit describes: the tag and the artifact
# disagree, and the next checkout silently loses the difference.
DIRTY="$(git status --porcelain 2>/dev/null | sed '/^$/d')"
if [[ -n "$DIRTY" ]]; then
  N_DIRTY="$(echo "$DIRTY" | wc -l | tr -d ' ')"
  warn "working tree is DIRTY at release time (${N_DIRTY} entry/entries) — release ≠ any commit" \
       "commit or stash before releasing; run \`git status\` to review [drift]"
fi

# ---- release branch behind the base ref → stale base -----------------------------
if git rev-parse --verify --quiet "$BASE_REF" >/dev/null 2>&1; then
  BEHIND_MAIN="$(git rev-list --count "HEAD..${BASE_REF}" 2>/dev/null || echo 0)"
  if [[ "${BEHIND_MAIN:-0}" -gt 0 ]]; then
    warn "release branch is ${BEHIND_MAIN} commit(s) behind ${BASE_REF} — stale base" \
         "rebase onto ${BASE_REF} before releasing (avoids conflicts/regressions) [drift]"
  fi
fi

# =================================================================================
# COVERAGE: what this script does NOT catch (left to the LLM / blast-radius pass)
# =================================================================================
echo "───────────────────────────────────────────────────────────────"
echo " ⚠️  NOT covered by grep (delegate to the Blast-Radius/LLM pass):"
echo "    · a change to the return SHAPE of a function/endpoint (contract regression)"
echo "    · transactional read-after-write assumptions inside a single statement"
echo "    · UI singletons reused without resetting their state between opens"
echo "    · layout that collapses only on one engine · business invariants"
echo "    · authorization checks bypassed when called with elevated privileges"

# ---- verdict ---------------------------------------------------------------------
echo "═══════════════════════════════════════════════════════════════"
printf " result: %d CRITICAL · %d WARNING · %d INFO\n" "$CRIT" "$WARN" "$INFO"
echo "═══════════════════════════════════════════════════════════════"
if [[ "$CRIT" -gt 0 ]]; then exit 2; fi
if [[ "$WARN" -gt 0 ]]; then exit 1; fi
exit 0

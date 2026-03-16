#!/usr/bin/env bash
# codex-plan-review.sh - Send an implementation plan to OpenAI Codex for review
# Usage: echo "plan text" | codex-plan-review.sh
#    or: codex-plan-review.sh /path/to/plan.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CODEX="${CODEX_PATH:-codex}"
TIMEOUT_SEC="${CODEX_TIMEOUT:-600}"
OUTFILE="/tmp/codex_planreview_$$_$(date +%s).txt"
PROMPTFILE="/tmp/codex_planprompt_$$_$(date +%s).txt"

cleanup() { rm -f "$OUTFILE" "$PROMPTFILE"; }
trap cleanup EXIT

# Read plan from file arg or stdin
if [ -n "${1:-}" ] && [ -f "$1" ]; then
    PLAN_TEXT=$(cat "$1")
elif [ ! -t 0 ]; then
    PLAN_TEXT=$(cat)
else
    echo "[codex-plan-review] Usage: echo 'plan text' | codex-plan-review.sh"
    echo "                        or: codex-plan-review.sh /path/to/plan.md"
    exit 0
fi

if [ -z "$PLAN_TEXT" ]; then
    echo "[codex-plan-review] Error: empty plan text."
    exit 0
fi

# Write full prompt to temp file to avoid ARG_MAX issues
cat > "$PROMPTFILE" << 'HEREDOC_END'
You are reviewing an implementation plan created by another AI assistant (Claude). Evaluate this plan critically and constructively. Assess each of the following dimensions:

1. **Completeness**: Are all requirements addressed? Any gaps or missing steps?
2. **Correctness**: Is the technical approach sound? Any flawed assumptions or design errors?
3. **Risk areas**: What could go wrong? Edge cases missed? Potential failure modes?
4. **Alternatives**: Are there simpler or better approaches for any component?
5. **Sequencing**: Is the implementation order logical? Are dependencies correctly handled?

Be specific — cite which part of the plan you are commenting on. Prioritize feedback by importance (critical issues first). If the plan is solid, say so briefly and note any minor improvements.

Here is the plan to review:

HEREDOC_END

echo "$PLAN_TEXT" >> "$PROMPTFILE"

if timeout "$TIMEOUT_SEC" "$CODEX" exec \
    --ephemeral \
    --skip-git-repo-check \
    -s read-only \
    -o "$OUTFILE" \
    "$(cat "$PROMPTFILE")" >/dev/null 2>&1; then

    if [ -s "$OUTFILE" ]; then
        cat "$OUTFILE"
    else
        echo "[codex-plan-review] Codex returned empty response."
    fi
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -eq 124 ]; then
        echo "[codex-plan-review] Codex plan review timed out after ${TIMEOUT_SEC}s."
    else
        echo "[codex-plan-review] Codex plan review failed (exit code: $EXIT_CODE)."
    fi
fi

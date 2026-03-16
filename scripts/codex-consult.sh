#!/usr/bin/env bash
# codex-consult.sh - Ask OpenAI Codex for a second opinion on a technical question
# Usage: codex-consult.sh "your question here"
#    or: echo "your question" | codex-consult.sh -
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CODEX="${CODEX_PATH:-codex}"
TIMEOUT_SEC="${CODEX_TIMEOUT:-600}"
OUTFILE="/tmp/codex_consult_$$_$(date +%s).txt"

cleanup() { rm -f "$OUTFILE"; }
trap cleanup EXIT

# Read question from argument or stdin
if [ "${1:-}" = "-" ]; then
    QUESTION=$(cat)
elif [ -n "${1:-}" ]; then
    QUESTION="$1"
else
    echo "[codex-consult] Usage: codex-consult.sh \"your question here\""
    echo "                   or: echo \"question\" | codex-consult.sh -"
    exit 0
fi

if [ -z "$QUESTION" ]; then
    echo "[codex-consult] Error: empty question."
    exit 0
fi

PROMPT="You are being consulted as an external technical reviewer. Another AI assistant (Claude) is working on a problem and wants your independent assessment. Be concise, specific, and actionable in your response. Focus on what matters most.

Question:
$QUESTION"

if timeout "$TIMEOUT_SEC" "$CODEX" exec \
    --ephemeral \
    --skip-git-repo-check \
    -s read-only \
    -o "$OUTFILE" \
    "$PROMPT" >/dev/null 2>&1; then

    if [ -s "$OUTFILE" ]; then
        cat "$OUTFILE"
    else
        echo "[codex-consult] Codex returned empty response."
    fi
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -eq 124 ]; then
        echo "[codex-consult] Codex consultation timed out after ${TIMEOUT_SEC}s."
    else
        echo "[codex-consult] Codex consultation failed (exit code: $EXIT_CODE)."
    fi
fi

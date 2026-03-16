#!/usr/bin/env bash
# codex-code-review.sh - Run OpenAI Codex code review on current changes
# Usage: codex-code-review.sh [--uncommitted | --base BRANCH | --commit SHA]
#        Defaults to --uncommitted if no arguments given
# Uses `codex exec review --json` and extracts agent_message from JSONL output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CODEX="${CODEX_PATH:-codex}"
TIMEOUT_SEC="${CODEX_TIMEOUT:-600}"
JSONL_FILE="/tmp/codex_review_jsonl_$$_$(date +%s).txt"
OUTFILE="/tmp/codex_review_$$_$(date +%s).txt"

cleanup() { rm -f "$JSONL_FILE" "$OUTFILE"; }
trap cleanup EXIT

# Parse arguments
REVIEW_ARGS=""
CD_ARG=""
CUSTOM_PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base)
            REVIEW_ARGS="--base $2"
            shift 2
            ;;
        --commit)
            REVIEW_ARGS="--commit $2"
            shift 2
            ;;
        --cd)
            CD_ARG="-C $2"
            shift 2
            ;;
        --prompt)
            CUSTOM_PROMPT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Default to --uncommitted
if [ -z "$REVIEW_ARGS" ]; then
    REVIEW_ARGS="--uncommitted"
fi

# Check for git repo and changes (if using --uncommitted)
if [[ "$REVIEW_ARGS" == "--uncommitted" ]] && [ -z "$CD_ARG" ]; then
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "[codex-code-review] Not in a git repository."
        exit 0
    fi
    CHANGES=$(git status --porcelain 2>/dev/null)
    if [ -z "$CHANGES" ]; then
        echo "[codex-code-review] No uncommitted changes to review."
        exit 0
    fi
fi

# Build command array - use `codex exec review --json` to get structured output
CMD=(timeout "$TIMEOUT_SEC" "$CODEX" exec review $REVIEW_ARGS --json)
if [ -n "$CD_ARG" ]; then
    CMD+=($CD_ARG)
fi
if [ -n "$CUSTOM_PROMPT" ]; then
    CMD+=("$CUSTOM_PROMPT")
fi

if "${CMD[@]}" > "$JSONL_FILE" 2>/dev/null; then
    # Extract the last agent_message from the JSONL output
    # Look for lines with type "item.completed" containing "agent_message"
    python3 -c "
import json, sys
messages = []
for line in open('$JSONL_FILE'):
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'item.completed':
            item = obj.get('item', {})
            if item.get('type') == 'agent_message':
                messages.append(item.get('text', ''))
    except json.JSONDecodeError:
        continue
if messages:
    print(messages[-1])
else:
    print('[codex-code-review] Codex review completed but no review message found.')
" 2>/dev/null || echo "[codex-code-review] Codex review completed but could not parse output. Ensure python3 is installed."
else
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -eq 124 ]; then
        echo "[codex-code-review] Codex review timed out after ${TIMEOUT_SEC}s."
    else
        echo "[codex-code-review] Codex review failed (exit code: $EXIT_CODE)."
    fi
fi

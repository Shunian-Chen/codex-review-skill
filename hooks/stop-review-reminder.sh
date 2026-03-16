#!/usr/bin/env bash
# stop-review-reminder.sh - Stop hook: remind about Codex review if there are uncommitted code changes
# This hook outputs a systemMessage (advisory, non-blocking) when changes exist.
set -euo pipefail

# Read stdin (hook input JSON) - consume it to avoid broken pipe
cat > /dev/null

# Check if we're in a git repo with uncommitted changes
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHANGES=$(git status --porcelain 2>/dev/null | head -5)
    if [ -n "$CHANGES" ]; then
        # Count changed files
        FILE_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        echo "{\"systemMessage\":\"[codex-review] There are ${FILE_COUNT} uncommitted file change(s) in this repository. Consider running Codex code review (/codex-code-review) for external validation before finalizing.\"}"
        exit 0
    fi
fi

# No changes or not in git repo - no-op
echo '{}'
exit 0

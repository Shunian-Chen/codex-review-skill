#!/usr/bin/env bash
# install.sh - Install codex-review-skill plugin for Claude Code
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_NAME="codex-review-skill"
TARGET_DIR="${HOME}/.claude/plugins/${PLUGIN_NAME}"

echo "=== codex-review-skill installer ==="
echo ""

# Check prerequisites
MISSING=""

if ! command -v codex >/dev/null 2>&1; then
    MISSING="${MISSING}  - codex CLI (https://github.com/openai/codex)\n"
fi

if ! command -v python3 >/dev/null 2>&1; then
    MISSING="${MISSING}  - python3 (required for parsing Codex JSONL output)\n"
fi

if [ -n "$MISSING" ]; then
    echo "Missing prerequisites:"
    echo -e "$MISSING"
    echo "Please install the above and re-run this script."
    exit 1
fi

echo "[ok] codex CLI found: $(command -v codex)"
echo "[ok] python3 found: $(command -v python3)"

# Set executable permissions
chmod +x "${PLUGIN_DIR}/scripts/"*.sh
chmod +x "${PLUGIN_DIR}/hooks/"*.sh
echo "[ok] Script permissions set"

# Create symlink
if [ -L "$TARGET_DIR" ]; then
    echo "[ok] Symlink already exists: ${TARGET_DIR}"
elif [ -e "$TARGET_DIR" ]; then
    echo "[warning] ${TARGET_DIR} already exists but is not a symlink. Skipping."
    echo "          Remove it manually if you want to re-link."
else
    mkdir -p "$(dirname "$TARGET_DIR")"
    ln -s "$PLUGIN_DIR" "$TARGET_DIR"
    echo "[ok] Symlink created: ${TARGET_DIR} -> ${PLUGIN_DIR}"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  1. Start Claude Code normally - the plugin will be loaded automatically"
echo "  2. Or specify explicitly: claude --plugin-dir ${PLUGIN_DIR}"
echo ""
echo "Available commands:"
echo "  /codex-consult       - Ask Codex a technical question"
echo "  /codex-code-review   - Review current code changes"
echo "  /codex-plan-review   - Review an implementation plan"

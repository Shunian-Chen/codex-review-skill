---
description: Send an implementation plan to OpenAI Codex for external review and validation
argument-hint: "[plan file path]"
allowed-tools: Bash, Read, Glob
---

Send an implementation plan to OpenAI Codex for critical review. To do this, follow these steps:

1. Obtain the plan text:
   - If `$ARGUMENTS` contains a file path, read that file to get the plan text
   - If `$ARGUMENTS` is empty, look for the most recent plan file in the current `.claude/plans/` directory, or use the plan most recently discussed in conversation context
   - If no plan can be found, ask the user to provide the plan text or file path

2. Send the plan to Codex for review:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-plan-review.sh" "/path/to/plan/file"
```
   Or if the plan is from conversation context, write it to a temp file first:
```bash
cat > /tmp/plan_to_review.md << 'EOF'
<plan content here>
EOF
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-plan-review.sh" /tmp/plan_to_review.md
```

3. Present the Codex review under a clear header: **Codex Plan Review:**

4. Synthesize the feedback:
   - For each point Codex raised, assess whether it is valid
   - Highlight the most important suggestions that should be incorporated
   - Note any concerns you disagree with, explaining your reasoning
   - If Codex found gaps you missed, acknowledge them

5. Propose an updated plan incorporating the valid feedback, clearly marking what changed and why.

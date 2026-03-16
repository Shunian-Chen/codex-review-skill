---
description: Run OpenAI Codex code review on current uncommitted changes or a specific branch/commit
argument-hint: "[--base BRANCH | --commit SHA]"
allowed-tools: Bash, Read, Glob, Grep
---

Run an external code review using OpenAI Codex on current code changes. To do this, follow these steps:

1. Parse `$ARGUMENTS` for optional flags:
   - `--base BRANCH`: Review changes against a specific base branch
   - `--commit SHA`: Review a specific commit
   - No arguments: Review all uncommitted changes (default)

2. First check the current state:
```bash
git status --porcelain
```
   If there are no changes and no flags were provided, inform the user there is nothing to review.

3. Run the Codex code review:
```bash
bash scripts/codex-code-review.sh $ARGUMENTS
```

4. Present the Codex review results under a clear header: **Codex Code Review:**

5. Analyze the review findings:
   - Categorize issues by severity (critical bugs > logic errors > style/minor)
   - For each issue Codex raised, state whether you agree or disagree, with reasoning
   - If Codex found issues you missed, acknowledge them

6. If actionable issues were found, offer to fix them immediately. List specific fixes you would make and ask the user for permission to proceed.

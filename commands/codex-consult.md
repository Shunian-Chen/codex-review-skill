---
description: Ask OpenAI Codex for a second opinion on a question or problem
argument-hint: "<question>"
allowed-tools: Bash, Read, Grep
---

Ask OpenAI Codex for a second opinion on the given question. To do this, follow these steps:

1. Parse `$ARGUMENTS` as the question to send to Codex. If no arguments are provided, ask the user what question they want to consult Codex about.

2. **Gather concrete context** before formulating the question for Codex:
   - Use Read to read the specific source files involved in the question
   - Identify exact file paths, line numbers, function/class names
   - Copy the actual code snippets (5-30 lines) that are relevant
   - Collect exact error messages, stack traces, or unexpected output if applicable
   - Note what was tried and the specific result of each attempt

3. Before calling Codex, briefly state your own current analysis or position on the question, so the user can later compare it with Codex's response.

4. **Formulate a precise question** that includes:
   - Exact file paths (e.g., `src/auth/handler.py:45`)
   - Actual code snippets (pasted from the files you read, not paraphrased)
   - Exact error messages or unexpected behavior
   - Specific changes tried and their results
   - One focused question about a specific aspect

   **Do NOT** send vague questions like "how should I handle X" or "what's the best approach for Y" without file paths and code.

5. Run the consultation:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-consult.sh" "$QUESTION"
```

6. Present the Codex response under a clear header: **Codex Second Opinion:**

7. Compare Codex's answer with your own analysis:
   - Highlight points of agreement (strengthens confidence)
   - Highlight points of disagreement (explain trade-offs of each approach)
   - If Codex identified something you missed, acknowledge and incorporate it

8. Provide a synthesized recommendation to the user, noting which source (your analysis vs Codex) each point comes from.

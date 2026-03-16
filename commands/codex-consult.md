---
description: Ask OpenAI Codex for a second opinion on a question or problem
argument-hint: "<question>"
allowed-tools: Bash, Read, Grep
---

Ask OpenAI Codex for a second opinion on the given question. To do this, follow these steps:

1. Parse `$ARGUMENTS` as the question to send to Codex. If no arguments are provided, ask the user what question they want to consult Codex about.

2. Before calling Codex, briefly state your own current analysis or position on the question, so the user can later compare it with Codex's response.

3. Run the consultation:
```bash
bash scripts/codex-consult.sh "$ARGUMENTS"
```

4. Present the Codex response under a clear header: **Codex Second Opinion:**

5. Compare Codex's answer with your own analysis:
   - Highlight points of agreement (strengthens confidence)
   - Highlight points of disagreement (explain trade-offs of each approach)
   - If Codex identified something you missed, acknowledge and incorporate it

6. Provide a synthesized recommendation to the user, noting which source (your analysis vs Codex) each point comes from.

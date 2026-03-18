---
name: codex-second-opinion
description: This skill should be used when Claude Code encounters uncertainty about a problem diagnosis, when debugging attempts have failed twice or more, when the user signals frustration ("still broken", "that didn't work", "try something else"), when choosing between multiple viable implementation approaches, when working on security-sensitive code (auth, encryption, access control), when completing an implementation plan that needs external validation, or when finishing code modifications that should be reviewed for correctness and bugs.
version: 1.0.0
---

# Codex Second Opinion

This skill enables consulting OpenAI Codex as an external technical reviewer. Codex runs as a separate AI system (GPT-5.4) and provides independent analysis, catching blind spots and validating decisions.

## When to Invoke Codex

Automatically invoke Codex consultation when ANY of these conditions apply:

### 1. Diagnostic Uncertainty (Auto-Consult)
- Multiple possible root causes identified and cannot confidently narrow down
- Working with unfamiliar APIs, libraries, or system internals
- Error messages are ambiguous or could indicate several different issues

### 2. Circular Debugging (Auto-Consult)
- Two or more fix attempts have failed on the same issue
- Each attempted solution reveals a different aspect of the problem
- The debugging path is not converging toward a solution

### 3. User Frustration Signals (Auto-Consult)
- User says: "that didn't work", "still broken", "try again", "different approach"
- User reverts suggested changes
- User questions the diagnosis or approach

### 4. Architecture and Design Decisions (Auto-Consult)
- Choosing between fundamentally different implementation patterns
- Deciding on data structures, algorithms, or system design trade-offs
- Making decisions that are expensive to reverse later

### 5. Security-Sensitive Code (Auto-Consult)
- Authentication, authorization, or access control logic
- Encryption, hashing, or token handling
- Input validation for security boundaries

### 6. Plan Completion (Auto Plan Review)
- After creating or finalizing an implementation plan
- After significant plan revisions
- Before presenting a plan for user approval

### 7. Code Modification Completion (Auto Code Review)
- After completing multi-file code changes
- After implementing a new feature or fixing a complex bug
- Before suggesting the user commit changes

## How to Consult Codex

**Important**: Before calling any script, the plugin root is available via `${CLAUDE_PLUGIN_ROOT}`.

### External Consultation (Second Opinion)

Formulate a **precise, specific** question. Every consultation MUST include concrete details — never send vague or generic questions. Follow this checklist:

#### Required in every question:
1. **Exact file paths** — which files are involved (e.g., `src/auth/jwt_handler.py`, `pkg/api/router.go:142`)
2. **Actual code snippets** — the relevant function, class, or block (not paraphrased, copy the real code)
3. **Exact error messages** — full error text, stack traces, or unexpected output (not "it errors" or "it fails")
4. **What was tried and the specific result** — "Changed X in file Y, got error Z" (not "tried a few things")
5. **One focused question** — ask about one specific thing, not "what do you think about this code"

#### Question structure:

```
File(s): [exact file paths involved]
Code: [paste the relevant code snippet, 5-30 lines]
Error/Issue: [exact error message or unexpected behavior]
Tried: [specific change → specific result, for each attempt]
Question: [one precise question about a specific aspect]
```

#### Good example:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-consult.sh" "File: src/db/session.py:45-62 and src/api/users.py:128. Code in session.py: 'def get_session(): engine = create_engine(DB_URL); Session = sessionmaker(bind=engine); return Session()'. Code in users.py: 'user = session.query(User).first(); session.close(); return user.profile'. Error: 'sqlalchemy.orm.exc.DetachedInstanceError: Parent instance <User> is not bound to a Session; lazy load operation of attribute profile cannot proceed'. Tried: 1) Added joinedload(User.profile) in users.py:128 → same error. 2) Set expire_on_commit=False in session.py:48 → error disappears but stale data returned. Question: In SQLAlchemy 2.0, should I use scoped_session with a request-level lifecycle instead of manually closing, or is there a better pattern for lazy-loaded relationships that cross the session boundary?"
```

#### Bad examples (DO NOT do this):
- "How should I handle database sessions?" — too vague, no file or code context
- "I'm getting an error with SQLAlchemy" — no error message, no code, no file path
- "What's the best way to do authentication?" — no project context, not specific to any code

### Plan Review

After completing a plan, write it to a temp file and send for review:

```bash
cat > /tmp/plan_for_codex.md << 'PLAN_EOF'
[full plan text here]
PLAN_EOF
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-plan-review.sh" /tmp/plan_for_codex.md
```

### Code Review

After completing code changes, run the review on uncommitted changes:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-code-review.sh"
```

Or review against a specific branch:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/codex-code-review.sh" --base main
```

## Interpreting and Presenting Results

After receiving Codex's response, follow this protocol:

1. **Acknowledge the consultation**: Tell the user "I consulted Codex (GPT-5.4) for an external perspective."

2. **Present Codex's key points**: Summarize the most important findings clearly.

3. **Compare with own analysis**:
   - **Agreement**: "Both Claude and Codex agree that..." — proceed with higher confidence
   - **New insight from Codex**: "Codex identified something I missed: ..." — incorporate it
   - **Disagreement**: "Codex suggests X, while I believe Y because..." — present both with reasoning, let the user decide

4. **Synthesized recommendation**: Provide a final recommendation combining the best of both perspectives.

## Important Guidelines

- Always tell the user when Codex is being consulted — transparency is essential
- Do not call Codex for trivial questions (typos, formatting, simple syntax)
- If Codex is unavailable or times out, proceed with own analysis and note the failed consultation
- **Every question MUST include specific file paths, actual code snippets, and exact error messages** — never send generic or abstract questions
- Before sending a question, read the relevant source files to gather exact code and context — do not rely on memory or paraphrasing
- Include relevant code snippets in consultation prompts when applicable
- For code review, ensure changes are saved to disk before calling the review script

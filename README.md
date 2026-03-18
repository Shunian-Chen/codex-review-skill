# codex-review-skill

A Claude Code plugin that integrates OpenAI Codex CLI as an external reviewer, enabling Claude to automatically seek second opinions, validate implementation plans, and review code changes through a separate AI system.

## Motivation

When Claude Code works on complex problems, it may encounter blind spots, diagnostic uncertainty, or situations where an independent perspective would improve the outcome. This plugin bridges Claude Code (Claude Opus) and OpenAI Codex CLI (GPT-5.4), creating a dual-AI validation workflow:

- **Reduce hallucination risk** by cross-checking conclusions across two independent AI systems
- **Catch blind spots** that a single model might miss
- **Improve code quality** through automated external review before committing

## Features

### 1. Auto-Consult (Second Opinion)

Claude Code automatically consults Codex when it encounters uncertainty:

- Ambiguous error diagnosis with multiple possible root causes
- Debugging loops (2+ failed fix attempts on the same issue)
- User frustration signals ("still broken", "try something else")
- Architecture/design decisions between competing approaches
- Security-sensitive code (auth, encryption, access control)

### 2. Plan Review

After Claude Code creates an implementation plan, it automatically sends it to Codex for review across five dimensions:

- **Completeness** -- any gaps or missing steps?
- **Correctness** -- any flawed assumptions or design errors?
- **Risk areas** -- edge cases, failure modes?
- **Alternatives** -- simpler or better approaches?
- **Sequencing** -- logical order, correct dependencies?

### 3. Code Review

After Claude Code completes code modifications, it automatically runs a Codex code review on the uncommitted changes to catch bugs, logic errors, and potential issues before the user commits.

## Installation

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [Codex CLI](https://github.com/openai/codex) installed and configured with an OpenAI API key
- `python3` available (for parsing Codex JSONL output)

### Setup

Clone the repository and run the install script:

```bash
git clone https://github.com/anthropics/codex-review-skill.git
cd codex-review-skill
bash install.sh
```

Or manually load the plugin by pointing Claude Code to the plugin directory:

```bash
claude --plugin-dir /path/to/codex-review-skill
```

To make this permanent, create a symlink:

```bash
ln -s /path/to/codex-review-skill ~/.claude/plugins/codex-review-skill
```

### Configuration

The plugin uses your existing Codex CLI configuration (`~/.codex/config.toml`). No additional API keys or configuration required.

**Optional environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_TIMEOUT` | `600` | Timeout in seconds for Codex calls |
| `CODEX_PATH` | `codex` | Path to the Codex CLI binary |

## Usage

### Slash Commands

| Command | Description | Example |
|---------|-------------|---------|
| `/codex-consult` | Ask Codex a technical question | `/codex-consult "Is using mutex or channel better for this Go concurrency pattern?"` |
| `/codex-code-review` | Review current code changes | `/codex-code-review` or `/codex-code-review --base main` |
| `/codex-plan-review` | Review an implementation plan | `/codex-plan-review /path/to/plan.md` |

### Automatic Triggers

When the plugin is loaded, Claude Code will automatically:

1. **Consult Codex** when it detects uncertainty in its own diagnosis or approach
2. **Request plan review** after completing an implementation plan
3. **Request code review** after completing significant code changes

The Stop hook also reminds Claude about unreviewed code changes when finishing a task.

### Script Usage (Direct)

The scripts can also be called directly from the terminal (run from the plugin directory):

```bash
cd /path/to/codex-review-skill

# Ask a question
bash scripts/codex-consult.sh "Your question here"

# Pipe a question from stdin
echo "Your question" | bash scripts/codex-consult.sh -

# Review uncommitted changes
bash scripts/codex-code-review.sh

# Review changes against a branch
bash scripts/codex-code-review.sh --base main

# Review a specific commit
bash scripts/codex-code-review.sh --commit abc123

# Review a plan
bash scripts/codex-plan-review.sh /path/to/plan.md

# Pipe plan text
echo "Step 1: ..." | bash scripts/codex-plan-review.sh
```

## Plugin Structure

```
codex-review-skill/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── .claude/
│   └── settings.local.json     # Plugin permission settings
├── commands/
│   ├── codex-consult.md         # /codex-consult slash command
│   ├── codex-code-review.md     # /codex-code-review slash command
│   └── codex-plan-review.md     # /codex-plan-review slash command
├── skills/
│   └── codex-second-opinion/
│       └── SKILL.md             # Auto-trigger skill definition
├── hooks/
│   ├── hooks.json               # Stop hook configuration
│   └── stop-review-reminder.sh  # Reminds about unreviewed changes
├── scripts/
│   ├── codex-consult.sh         # Core: send question to Codex
│   ├── codex-code-review.sh     # Core: run Codex code review
│   └── codex-plan-review.sh     # Core: send plan to Codex for review
├── install.sh                   # Installation script
├── README.md
└── README_CN.md                 # Chinese documentation
```

### How It Works

```
                    ┌─────────────────────┐
                    │     Claude Code      │
                    │   (Claude Opus 4)    │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     Skill triggers     User invokes     Stop hook
     automatically      /codex-xxx       reminds
              │                │                │
              └────────────────┼────────────────┘
                               │
                        Shell scripts
                    codex-consult.sh
                    codex-code-review.sh
                    codex-plan-review.sh
                               │
                    ┌──────────┴──────────┐
                    │     Codex CLI        │
                    │     (GPT-5.4)        │
                    └──────────┬──────────┘
                               │
                    Response returned to
                    Claude Code context
```

**Skill** (`codex-second-opinion`) is the core mechanism for automatic behavior. Its description lists specific trigger conditions (uncertainty, debugging loops, plan completion, code completion). When Claude Code detects these patterns in the conversation, it loads the skill and follows its instructions to call Codex.

**Scripts** wrap Codex CLI calls with error handling, timeout protection, and output parsing. They use `codex exec` for consultations and `codex exec review --json` for code reviews (parsing JSONL to extract the final agent message).

**Hook** (Stop event) provides a lightweight reminder when Claude is about to finish a task but there are uncommitted changes that haven't been reviewed.

## Technical Notes

- All Codex calls use `--ephemeral` and `-s read-only` (Codex never writes to your filesystem)
- Consultation calls use `--skip-git-repo-check` for lightweight execution
- Code review uses `codex exec review` (not `codex review`) because only the former supports output capture via `-o`
- JSONL output is parsed with `python3` to extract `agent_message` items
- All scripts exit 0 even on failure, printing descriptive error messages instead of crashing
- Temporary files are cleaned up via `trap cleanup EXIT`

## Customization

### Adjusting Auto-Trigger Sensitivity

Edit `skills/codex-second-opinion/SKILL.md` to modify when Claude automatically invokes Codex. The trigger conditions are listed in the "When to Invoke Codex" section -- add, remove, or rephrase conditions to tune the behavior.

### Changing the Review Hook Behavior

The Stop hook is advisory (non-blocking) by default. To make it more assertive, edit `hooks/hooks.json` and change the hook type or add prompt-based hooks that instruct Claude to always run a review before completing.

### Using a Different Codex Model

Override the model per-call:

```bash
CODEX_MODEL=o3 bash scripts/codex-consult.sh "question"
```

Or edit `~/.codex/config.toml` to change the default model globally.

## License

MIT

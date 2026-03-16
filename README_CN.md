# codex-review-skill

一个 Claude Code 插件，将 OpenAI Codex CLI 集成为外部审查员，使 Claude 能够自动寻求第二意见、验证实现计划、以及通过另一个独立 AI 系统审查代码变更。

## 为什么需要这个插件

当 Claude Code 处理复杂问题时，可能会遇到认知盲区、诊断不确定、或需要独立视角来改善结果的情况。本插件在 Claude Code（Claude Opus）和 OpenAI Codex CLI（GPT-5.4）之间架起桥梁，构建双 AI 验证工作流：

- **降低幻觉风险** —— 通过两个独立 AI 系统交叉验证结论
- **捕获认知盲区** —— 发现单一模型可能遗漏的问题
- **提升代码质量** —— 在提交前自动进行外部审查

## 核心功能

### 1. 自动咨询（寻求外援）

Claude Code 在遇到不确定性时自动咨询 Codex：

- 模糊的错误诊断，存在多个可能的根因
- 调试陷入循环（同一问题尝试 2 次以上修复仍失败）
- 用户表达不满信号（"还是不行"、"换个思路"、"试试别的"）
- 架构/设计决策，在多个方案之间难以抉择
- 安全敏感代码（认证、加密、访问控制）

### 2. 计划审核

Claude Code 创建实现计划后，自动发送给 Codex 从五个维度进行审核：

- **完整性** —— 是否有遗漏的步骤或需求？
- **正确性** —— 技术方案是否合理？有无错误的假设？
- **风险点** —— 边界情况、失败模式是否考虑到位？
- **替代方案** —— 是否存在更简洁或更优的实现路径？
- **执行顺序** —— 实现步骤是否逻辑通顺？依赖关系是否正确？

### 3. 代码审查

Claude Code 完成代码修改后，自动调用 Codex 对未提交的变更进行代码审查，在用户 commit 之前捕获 bug、逻辑错误和潜在问题。

## 安装

### 前置条件

- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- 已安装 [Codex CLI](https://github.com/openai/codex) 并配置好 OpenAI API Key
- 系统中可用 `python3`（用于解析 Codex JSONL 输出）

### 安装方式

克隆仓库并运行安装脚本：

```bash
git clone https://github.com/anthropics/codex-review-skill.git
cd codex-review-skill
bash install.sh
```

或手动启动 Claude Code 时指定插件目录：

```bash
claude --plugin-dir /path/to/codex-review-skill
```

如需永久生效，可创建符号链接至 Claude Code 插件目录：

```bash
ln -s /path/to/codex-review-skill ~/.claude/plugins/codex-review-skill
```

### 配置

插件直接使用现有的 Codex CLI 配置（`~/.codex/config.toml`），无需额外的 API Key 或配置。

**可选环境变量：**

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CODEX_TIMEOUT` | `600` | Codex 调用超时时间（秒） |
| `CODEX_PATH` | `codex` | Codex CLI 二进制文件路径 |

## 使用方式

### 斜杠命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `/codex-consult` | 向 Codex 请教技术问题 | `/codex-consult "Go 并发场景下用 mutex 还是 channel 更合适？"` |
| `/codex-code-review` | 审查当前代码变更 | `/codex-code-review` 或 `/codex-code-review --base main` |
| `/codex-plan-review` | 审核实现计划 | `/codex-plan-review /path/to/plan.md` |

### 自动触发

插件加载后，Claude Code 会在以下场景自动调用 Codex：

1. **自动咨询** —— 检测到自身诊断或方案存在不确定性时
2. **自动审核计划** —— 完成实现计划后
3. **自动代码审查** —— 完成重要代码修改后

Stop Hook 还会在任务结束时提醒 Claude 有未审查的代码变更。

### 直接调用脚本

三个核心脚本也可以直接在终端中调用：

```bash
# 提问
bash scripts/codex-consult.sh "你的问题"

# 通过 stdin 传入问题
echo "你的问题" | bash scripts/codex-consult.sh -

# 审查未提交的变更
bash scripts/codex-code-review.sh

# 审查相对于某个分支的变更
bash scripts/codex-code-review.sh --base main

# 审查某次提交
bash scripts/codex-code-review.sh --commit abc123

# 审核计划文件
bash scripts/codex-plan-review.sh /path/to/plan.md

# 通过管道传入计划文本
echo "步骤一: ..." | bash scripts/codex-plan-review.sh
```

## 插件结构

```
codex-review-skill/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据
├── .claude/
│   └── settings.local.json     # 插件权限配置
├── commands/
│   ├── codex-consult.md         # /codex-consult 斜杠命令
│   ├── codex-code-review.md     # /codex-code-review 斜杠命令
│   └── codex-plan-review.md     # /codex-plan-review 斜杠命令
├── skills/
│   └── codex-second-opinion/
│       └── SKILL.md             # 自动触发 Skill 定义
├── hooks/
│   ├── hooks.json               # Stop Hook 配置
│   └── stop-review-reminder.sh  # 提醒未审查的代码变更
├── scripts/
│   ├── codex-consult.sh         # 核心脚本：向 Codex 提问
│   ├── codex-code-review.sh     # 核心脚本：调用 Codex 代码审查
│   └── codex-plan-review.sh     # 核心脚本：发送计划给 Codex 审核
├── install.sh                   # 安装脚本
├── README.md
└── README_CN.md                 # 中文文档
```

### 工作原理

```
                    ┌─────────────────────┐
                    │     Claude Code      │
                    │   (Claude Opus 4)    │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
        Skill 自动触发    用户调用斜杠命令   Stop Hook
       （检测到不确定性）   /codex-xxx      （任务结束提醒）
              │                │                │
              └────────────────┼────────────────┘
                               │
                         Shell 脚本层
                    codex-consult.sh
                    codex-code-review.sh
                    codex-plan-review.sh
                               │
                    ┌──────────┴──────────┐
                    │     Codex CLI        │
                    │     (GPT-5.4)        │
                    └──────────┬──────────┘
                               │
                      响应返回至 Claude Code
                       上下文，综合分析后
                         呈现给用户
```

**Skill**（`codex-second-opinion`）是自动行为的核心机制。其描述列出了具体的触发条件（不确定性、调试循环、计划完成、代码完成等）。当 Claude Code 在对话中检测到这些模式时，会加载该 Skill 并按照指引调用 Codex。

**Scripts** 封装了 Codex CLI 调用，包含错误处理、超时保护和输出解析。咨询场景使用 `codex exec`，代码审查使用 `codex exec review --json`（解析 JSONL 提取最终的 agent message）。

**Hook**（Stop 事件）在 Claude 即将完成任务但存在未审查的代码变更时，提供轻量级提醒。该提醒为建议性质（非阻塞），不会打断工作流。

## 技术细节

- 所有 Codex 调用均使用 `--ephemeral` 和 `-s read-only`（Codex 不会写入你的文件系统）
- 咨询调用使用 `--skip-git-repo-check` 实现轻量级执行
- 代码审查使用 `codex exec review`（而非 `codex review`），因为只有前者支持通过 `-o` 捕获输出
- JSONL 输出通过 `python3` 解析，提取 `agent_message` 类型的条目
- 所有脚本即使遇到错误也返回 exit 0，输出描述性错误信息而非崩溃
- 临时文件通过 `trap cleanup EXIT` 自动清理

## 自定义

### 调整自动触发灵敏度

编辑 `skills/codex-second-opinion/SKILL.md`，修改 "When to Invoke Codex" 部分列出的触发条件。增加、删除或调整条件描述即可调节自动调用的频率。

### 修改 Hook 行为

Stop Hook 默认为建议性（非阻塞）。如需更强的约束：
- 编辑 `hooks/hooks.json` 修改 hook 类型
- 或添加 prompt-based hook，指示 Claude 在完成任务前必须执行代码审查

### 使用不同的 Codex 模型

单次调用时覆盖模型：

```bash
CODEX_MODEL=o3 bash scripts/codex-consult.sh "问题"
```

或编辑 `~/.codex/config.toml` 全局修改默认模型。

## 许可证

MIT

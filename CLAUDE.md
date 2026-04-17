# CLAUDE.md

> **Hub**: `D:\Claude\Ohmybrain` — 跨项目知识中心（查询领域知识/回流结论用 `/promote`）
> **模板**: `D:\Claude\ohmybrain-core` — 项目模板源

## 项目名称

UWAnet — 水声通信组网协议仿真平台。基于 Aqua-Sim-NG (ns-3) 构建，物理层复用 UWAcomm 成果。

## 关联项目

- **UWAcomm** (`D:\Claude\TechReq\UWAcomm`) — 物理层算法，OFDM/DSSS/FSK 可直接复用
- 前期调研材料：`raw/notes/uwanet-moc-v1.md`、`raw/notes/protocol-sim-brainstorm.md`

## 不可违反的规则

- 不得修改 `raw/` 下的文件，除非用户明确要求
- 优先更新 `wiki/` 而非在对话中重复分析
- 每个代码任务先在 `specs/active/` 写 spec
- 非平凡实现先在 `plans/` 写计划
- 代码变更必须附带测试，或说明为何不需要
- 知识变更必须同步更新 `wiki/index.md` 和 `wiki/log.md`
- 交付物不完整时不要停止

## 目录地图

| 目录 | 职责 |
|------|------|
| `raw/` | 只读原始资料（论文、文章、视频转录、笔记等） |
| `wiki/` | 项目知识层（概念、架构、模块、决策、摘要） |
| `specs/active/` | 当前任务 spec |
| `specs/archive/` | 已完成 spec |
| `plans/` | 实现计划 |
| `src/` | 源代码（ns-3 C++ 模块 + Python 分析脚本） |
| `tests/` | 自动化测试 |
| `evals/` | 评测 |
| `scripts/` | 自动化脚本 |
| `workflows/` | 操作流程文档 |
| `.claude/` | harness（rules/skills/hooks） |
| `.obsidian/` | Obsidian vault 配置 + wiki 页面模板 |

## 两个闭环

### 知识闭环

```
raw/ → ingest → wiki/ → query → promote → wiki/
```

### 开发闭环

```
01-spec → 02-plan → 03-implement(产出三件套) → 04-validate(验证+同步+归档+commit)
```

## 自动化保障（Hooks）

| 时机 | 检查内容 | 脚本 |
|------|---------|------|
| PreToolUse（Edit/Write） | 拦截 raw/ 写入 | `scripts/check_raw_write.py` |
| PreToolUse（Edit/Write） | 拦截 `<private>` 标签外泄到 wiki/ 等公开路径 | `scripts/check_private_tags.py` |
| PostToolUse（Edit/Write） | Wiki 结构快速检查 | `scripts/lint_wiki.py --quick` |
| Stop | Wiki index/log 同步检查 | `scripts/check_index_log_sync.py` |
| Stop | 任务完整性验证 | `scripts/validate_task.py` |

### Hook Exit Code Strategy

| Exit | 含义 | 触发效果 |
|------|------|---------|
| **0** | 成功 / 优雅放行 | 继续执行，stdout 可见 |
| **1** | 非阻断错误 | stderr 显示给用户，继续执行 |
| **2** | 阻断错误 | stderr 喂回 Claude，阻止工具调用 |

**设计原则**：宽松优先（未知输入 exit 0 放行）；阻断谨慎（仅安全性/一致性被破坏时 exit 2，如 `check_raw_write` / `check_private_tags` / `check_index_log_sync`）；非致命提醒用 exit 0 + stdout，避免打断工作流。Windows Terminal 下大量非 0 exit 可能导致 tab 累积。

## 常用命令

| 命令 | 用途 |
|------|------|
| `/ingest` | 摄入 raw/ 资料到 wiki/（7 步流程） |
| `/promote` | 回流跨项目结论到 Hub（5 步流程） |
| `python scripts/lint_wiki.py` | Wiki 结构检查 |
| `python scripts/sync_index.py` | 同步 index 页面计数 |
| `python scripts/validate_task.py` | 任务完成验证 |
| `python scripts/scrape.py <URL>` | Firecrawl 网页抓取到 raw/ |
| `python scripts/transcribe.py <文件>` | Whisper 音视频转录到 raw/ |

## 项目内导航

- **仪表盘**: `wiki/dashboard.md`
- **调研笔记**: `wiki/source-summaries/uwanet-brainstorm.md`

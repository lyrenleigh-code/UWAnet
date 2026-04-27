# 变更日志

> 记录每次对 wiki 的操作，最新的在最上面。

---

## [2026-04-27] sync | 从 dry-run worktree 同步规划文档 + Q1-Q4 决策

- **来源**：`D:/Claude/worktrees/uwanet-redo/`（2026-04-21 自主闭环 dry-run，Phase 3 Planner v2 Eval 92 PASS，Phase 4 真装机 2015/2015 编过）
- **新增规划文档**（v3，主仓首次落地）：
  - `specs/active/M0-charter.md` — M0 项目章程（9 条机器可判成功标准）
  - `plans/roadmap.md` — M1-M5 路线图（每里程碑含 Exit Criteria/依赖/工时）
  - `plans/architecture.md` — 6 层协议栈 + UWAcomm 接口表 + ns-3.41 依赖清单
  - `plans/risks.md` — 12 条风险（4 技术 / 5 外部依赖 / 3 时间）+ Q1-Q4 决策
- **新增 M1 三件套**（dry-run 已实测）：
  - `src/setup/install_ns3_aquasim.sh` — ns-3.41 + Aqua-Sim-NG 装机脚本
  - `tests/smoke/test_aqua_sim_aloha.py` — Smoke test（stub 模式 exit 0）
  - `workflows/01-env-setup.md` — WSL2 + ns-3 环境操作手册
- **新增 wiki/explorations**：
  - `wiki/explorations/uwanet-dryrun-2026-04-21.md` — dry-run 复盘（含 3 pitfall：subagent Bash / GCC -Werror / ns-3.41 API 变更）
- **更新**：`wiki/dashboard.md`（M0 → 🟢 已完成，M1 → 🟡 已规划；新增"规划文档"段 + Q1-Q4 决策表）；`wiki/index.md`（页面计数 7 → 8，Explorations 段新增 1 条）
- **Q1-Q4 决策**（详见 `plans/risks.md` §需决策）：
  - Q1：要求 UWAcomm 端实装逐帧 BER 持久化，走 PR 路径，**不接受**本项目侧合成兜底
  - Q2：smoke test `throughput` 单位 = bps
  - Q3：Aqua-Sim-NG 选 rmartin5/aqua-sim-ng（dry-run 实测过的 fork）
  - Q4：M3 PHY 占位、M4 才接真实 trace（依赖 R-X1 PR 合并）
- **顺手补**：04-21 ingest 留下的 5 份未追踪 source-summaries（aqua-sim-family / janus-standard / ns3-documentation-index / ns3-installation-guide / slotted-fama-mac）已 `git add` 入工作区
- **未做**：worktree 的 `goal.yaml` / `prompts/` / `.checkpoint/` / `scaffold-report.md` 是闭环 dry-run 专属资产，不进主仓

## [2026-04-21] ingest | 批量摄入 NS-3 + 水声网络论文资料

- **新增资料**（raw/，不可动）：
  - `raw/papers/` 4 篇：Aqua-Net (2009)、Aqua-Sim FG (2025)、Slotted FAMA (2006)、JANUS (2014)
  - `raw/courses/NS3资料/NS3安装教程/` 3 份 CSDN 博客（WSL2+Ubuntu+VSCode 环境搭建）
  - `raw/courses/NS3资料/NS3官方文档/` 11 份 ns-3 官方文档（manual/tutorial/model-library 多版本）
- **产出 5 份 source-summary**：
  - `wiki/source-summaries/ns3-installation-guide.md` — WSL2 路线，避开 /mnt 编译慢坑
  - `wiki/source-summaries/ns3-documentation-index.md` — 官方文档索引 + 推荐阅读顺序
  - `wiki/source-summaries/aqua-sim-family.md` — Aqua-Net 架构 + Aqua-Sim 四代演进 + UW-Aloha 案例
  - `wiki/source-summaries/slotted-fama-mac.md` — 时隙化 FAMA 协议，M3 MAC 实现蓝本
  - `wiki/source-summaries/janus-standard.md` — NATO 水声标准，可作 baseline PHY + 互操作桥
- **更新**：`wiki/index.md`（页面总数 2 → 7）
- **辅助工具**：`D:/Claude/Ohmybrain/scripts/extract_pdf.py`（PyMuPDF 实现的 PDF 文本提取，支持批量/单文件模式，未来可复用）
- **未建**：concepts/ entities/ 仍空；待 M1 真动手时再按需从 source-summaries 抽取

## [2026-04-13] init | 基础设施对齐 + 知识摄入

- 修复 hook 脚本（check_raw_write.py stdin + exit(2)，check_index_log_sync.py exit(2)）
- 更新 .claude/rules/（raw、wiki、engineering、specs）
- 补全 .claude/skills/（5 个）和 .claude/commands/（ingest、promote）
- 摄入 raw/notes/ 调研笔记 → wiki/source-summaries/uwanet-brainstorm.md
- 创建仪表盘 wiki/dashboard.md

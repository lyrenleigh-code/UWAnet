---
type: spec
created: 2026-04-21
updated: 2026-04-27
tags: [charter, M0, UWAnet, 规划]
status: active
---

# M0: 项目章程 — UWAnet

> **来源**：2026-04-21 dry-run worktree（`D:/Claude/worktrees/uwanet-redo/`）Phase 3 Planner v2 产出（Opus 4.7，Evaluator 92 PASS）。
> 2026-04-27 同步回主仓时去除 dry-run/goal.yaml 痕迹，规划内容不变。
> **对口规划产物**：[[plans/roadmap.md]] / [[plans/architecture.md]] / [[plans/risks.md]]
> **dry-run 复盘**：[[wiki/explorations/uwanet-dryrun-2026-04-21]]

## 项目定位

UWAnet 是一个**水声通信组网协议仿真平台**，基于 Aqua-Sim-NG(ns-3) 在 WSL2/Ubuntu
栈上构建 MAC 与网络层协议栈，并通过文件/数据接口复用姊妹项目
[[D:/Claude/TechReq/UWAcomm/wiki/index.md]] 已实现的
6 种物理层体制(SC-TDE / SC-FDE / DSSS / OFDM / OTFS / FH-MFSK)作为声学链路模型。
目标受众是课题组内部研究生与 Claude Code agent:前者在平台上做 MAC 对比实验、
后者在平台上做自动化参数扫描与报告生成。核心价值:**把"信号级仿真"(UWAcomm)与
"协议级仿真"(ns-3) 打通**,形成一条从比特→帧→包→组网吞吐的完整评测链路
(参见 [[raw/notes/uwanet-moc-v1.md]] §与 UWAcomm 的关系)。

## 范围界定

### 做什么

1. **环境基础(M1)**:WSL2 + Ubuntu 22.04 + ns-3.41 + Aqua-Sim-NG 一键安装脚本,
   example 级 smoke test 跑通([[wiki/source-summaries/ns3-installation-guide]])。
2. **MAC 层协议族(M2-M3)**:以 Aqua-Sim-NG 自带 `aqua-sim-mac-aloha.cc` 为起点,
   依序实现并对比三个 MAC:**Slotted ALOHA(baseline) → Slotted FAMA(RTS/CTS) → MACA-U**。
   对标 [[wiki/source-summaries/slotted-fama-mac]] Fig.4 时序与公式 (2) 吞吐上界。
3. **网络层路由(M4)**:实现 **VBF(Vector-Based Forwarding)**,验证端到端多跳
   投递成功率;DBR/EEDBR 列入 Nice-to-have。
4. **跨项目 PHY 接口(M2/M3 伴随)**:定义一个**最小可行接口**,让 Aqua-Sim-NG 的
   PhyLayer 可以在 C++ 侧消费 UWAcomm 产生的 BER/SNR/信道 trace,而不必在 ns-3
   里重实现 OFDM。采用**文件级 JSON/CSV trace 交换**作为 v1 形式
   (详见 [[plans/architecture.md]] §与 UWAcomm 的接口表)。
5. **参数扫描 + 可视化(M4)**:节点数、slot 长度、包到达率三维扫描,用 matplotlib
   + NetAnim 生成吞吐/端到端时延/投递率曲线。
6. **知识同步(贯穿)**:重要决策、调试坑、性能结论回流 `wiki/` 与 Hub。

### 不做什么(详见下节 ## 非目标)

## 非目标

- ❌ **不在 ns-3 里重造物理层**:OFDM/DSSS/FSK 完全留在 UWAcomm MATLAB 侧;
  ns-3 侧只消费 trace、不做样点级信号处理。
- ❌ **不做硬件联调**:不接 Teledyne Benthos / Micro-modem 实物;不做 JANUS
  标准的合规测试([[wiki/source-summaries/janus-standard]])(列入未来 Nice-to-have)。
- ❌ **不调优 C++ 编译器/构建系统**:容忍 ns-3 默认 `./ns3 build`,不改 CMake
  高级选项、不追求 ccache 最优。
- ❌ **不做 Aqua-Sim-TG/FG 集成**:半物理 testbed 与 MATLAB-C++ 混合编程
  ([[wiki/source-summaries/aqua-sim-family]])留给后续项目,本次只用**稳定的 NG**。
- ❌ **不做 Windows 原生 ns-3**:官方 ≥3.36 已放弃 Win 原生支持
  ([[wiki/source-summaries/ns3-installation-guide]] §官方系统要求)。
- ❌ **不做 Python binding**:ns-3 Python 绑定体验不稳定,实验编排统一用
  bash + C++ main 函数,后处理用独立 Python 脚本。
- ❌ **不做正式的 UWAcomm ↔ ns-3 双向实时耦合**:v1 只做单向离线 trace 注入;
  实时 socket/ZMQ/cppyy 留作后续升级路径。

## 成功标准

M0 结束时满足以下**机器可判且独立可验**的条件,每条由独立命令/文件/数值判定,
**禁止循环引用 Planner 自评或 Evaluator 自评**:

| # | 标准 | 验证方法 |
|---|------|---------|
| 1 | 4 份规划文档齐备 | `ls specs/active/M0-charter.md plans/roadmap.md plans/architecture.md plans/risks.md` 全部存在 |
| 2 | 章程 4 段完整 | `grep -c "^## 项目定位\|^## 范围界定\|^## 非目标\|^## 成功标准" specs/active/M0-charter.md` ≥ 4 |
| 3 | 架构图覆盖 ≥ 5 层 | `grep -cE "subgraph (APP\|TRAN\|NET\|MAC\|PHY\|CH)" plans/architecture.md` ≥ 5 |
| 4 | UWAcomm 接口表存在 | `grep -n "^### 3.2 接口表" plans/architecture.md` 命中 1 行 |
| 5 | 里程碑 ≥ 4 个且每个含 exit_criteria/依赖/预估工时 | `grep -c "^### 目标" plans/roadmap.md` ≥ 4 且每节后续 20 行内均有 `### Exit Criteria` / `### 依赖` / `### 预估工时` |
| 6 | 风险 ≥ 5 条,覆盖技术/外部依赖/时间 3 类 | `grep -cE "^\| R-[TXM][0-9]" plans/risks.md` ≥ 5 且 T/X/M 三前缀均存在 |
| 7 | 识别 UWAcomm/ns-3/Aqua-Sim-NG 三依赖 | 三关键词均在 `plans/architecture.md` 且在 `plans/risks.md` 出现(`grep -l` 均命中) |
| 8 | wikilink 引用 ≥ 5 处且全部 fs 可解析 | 唯一 wikilink 去重计数 ≥ 5;且每个 link 至少含 `/`(无 Obsidian-style 短名裸引用) |
| 9 | 四份文档末尾含 Changelog | `grep -c "^## Changelog" specs/active/M0-charter.md plans/roadmap.md plans/architecture.md plans/risks.md` 累计 ≥ 4 |

## 引用来源

- [[raw/notes/uwanet-moc-v1.md]] §协议栈架构,§与 UWAcomm 的关系,§里程碑
- [[raw/notes/protocol-sim-brainstorm.md]] §二 仿真平台选择,§四 代码结构,§九 学习路线
- [[wiki/source-summaries/uwanet-brainstorm]] §核心结论,§MAC 协议分类
- [[wiki/source-summaries/aqua-sim-family]] §家族谱系,§对 UWAnet 的启示
- [[wiki/source-summaries/slotted-fama-mac]] §M3 里程碑直接对标
- [[wiki/source-summaries/janus-standard]] §对 UWAnet 的使用价值(可选 baseline)
- [[wiki/source-summaries/ns3-installation-guide]] §推荐路线,§常见坑位
- [[wiki/source-summaries/ns3-documentation-index]] §对 UWAnet 的重点章节
- [[D:/Claude/TechReq/UWAcomm/wiki/index.md]] §Modules(13 个物理层模块函数清单)

## Changelog

- **v1 (2026-04-21)**:dry-run worktree 首次生成。
- **v2 (2026-04-21)**:dry-run worktree 响应 `.checkpoint/eval-1.md` 反馈,
  把 Obsidian-style 裸 wikilink 改为 fs 可解析路径,删循环引用 Planner 自评的
  成功标准条目,改散文化 EC 为 `grep` 命中数/exit code 等机器可判命令。
- **v3 (2026-04-27)**:从 worktree 同步回主仓(`D:/Claude/TechReq/UWAnet/`),
  删 `goal.yaml` 引用与 dry-run 痕迹;`raw/seed/` 路径改为主仓 `raw/notes/`;
  ns-3 版本表述对齐 dry-run 实测的 `ns-3.41`(原文 3.36 是预估)。

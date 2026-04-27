---
type: topic
created: 2026-04-13
updated: 2026-04-27
tags: [仪表盘, 项目管理]
---

# 项目仪表盘

> 更新日期：2026-04-27
> 导航：调研笔记 [[uwanet-brainstorm]] | 规划文档 [[../specs/active/M0-charter]]

---

## 项目概要

| 项 | 值 |
|---|---|
| 目标 | 基于 Aqua-Sim-NG (ns-3.41) 构建水声网络协议仿真平台 |
| 物理层 | 复用 UWAcomm（OFDM/DSSS/FH-MFSK）— 走 trace 文件接口 |
| 重点 | MAC 层协议（Slotted ALOHA / Slotted FAMA / MACA-U） |
| 阶段 | M0 收口 → M1 装机（dry-run 已实测过） |

---

## 里程碑

| 阶段 | 内容 | 状态 |
|------|------|------|
| **M0** | 前期调研与规划文档（charter / roadmap / architecture / risks） | 🟢 已完成（v3 落地 2026-04-27） |
| **M1** | ns-3.41 + Aqua-Sim-NG 环境搭建 | 🟡 已规划（脚本 + smoke test + workflow 落地，待主仓装机复刻） |
| M2 | 读懂 aqua-sim-mac-aloha.cc + PHY trace schema 定义 | 🔴 待做 |
| M3 | 实现自定义 MAC（Slotted ALOHA + Slotted FAMA），PHY 占位 trace | 🔴 待做 |
| M4 | 参数扫描 + 性能分析 + 接入真实 UWAcomm trace | 🔴 待做（依赖 R-X1 PR） |
| M5 | VBF 路由 + JANUS baseline PHY | ⚪ Nice-to-have |

---

## 规划文档（v3，2026-04-27 同步自 dry-run worktree）

- [[../specs/active/M0-charter]] — M0 项目章程（项目定位 / 范围 / 非目标 / 9 条机器可判成功标准）
- [[../plans/roadmap]] — M1-M5 路线图（每个里程碑含 Exit Criteria / 依赖 / 工时）
- [[../plans/architecture]] — 6 层协议栈（Mermaid）+ UWAcomm 接口表
- [[../plans/risks]] — 12 条风险（4 技术 / 5 外部依赖 / 3 时间）+ Q1-Q4 决策
- [[uwanet-dryrun-2026-04-21|dry-run 复盘]] — 真装机 PASS + 3 个 pitfall（含 GCC -Werror / ns-3.41 API 变更）

---

## 知识库

- 调研笔记：[[uwanet-brainstorm]]（平台选型、协议分类、环境搭建）
- ns-3 装机：[[ns3-installation-guide]] / [[ns3-documentation-index]]
- Aqua-Sim 家族：[[aqua-sim-family]]
- MAC 协议：[[slotted-fama-mac]] / [[janus-standard]]
- 原始资料：`raw/notes/`（2 篇调研笔记）+ `raw/papers/`（4 篇论文）+ `raw/courses/NS3资料/`

---

## Q1-Q4 决策（2026-04-27）

| # | 问题 | 决策 |
|---|------|------|
| Q1 | UWAcomm BER 持久化粒度 | 要求 UWAcomm 端实装逐帧持久化（走 PR 路径） |
| Q2 | smoke test throughput 单位 | bps |
| Q3 | Aqua-Sim-NG 仓库选择 | rmartin5/aqua-sim-ng |
| Q4 | M3 是否要求真实 trace | M3 占位、M4 才接真实 |

详见 [[../plans/risks#需决策2026-04-27-已逐条裁决]]。

---

## Hub 关联

- [underwater-acoustic-communication](../../Ohmybrain/wiki/concepts/underwater-acoustic-communication.md)
- [mobile-communication](../../Ohmybrain/wiki/concepts/mobile-communication.md)
- [autonomous-new-project-workflow](../../Ohmybrain/wiki/explorations/autonomous-new-project-workflow.md) — dry-run 方法论参考

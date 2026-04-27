---
type: source-summary
source_type: course
created: 2026-04-21
updated: 2026-04-21
tags: [ns-3, 官方文档, 手册, tutorial, 索引]
---

# NS-3 官方文档索引

> **原始资料**：`raw/courses/NS3资料/NS3官方文档/` 共 11 份 PDF

## 文档分层

ns-3 官方文档分三大核心 + 三个辅助资料：

| 层级 | 用途 | 本地文件 |
|------|------|---------|
| **入门** | 手把手教程，从 hello-simulator 到自定义场景 | `ns-3-tutorial-3.34.pdf` / `ns-3-tutorial-3.40.pdf` |
| **核心** | 框架手册：事件驱动引擎、节点、通道、日志 | `ns-3-manual-3.34.pdf` / `ns-3-manual-3.40.pdf` / `ns-3-manual-3.41.pdf` / `ns-3-manual.pdf` |
| **模块** | 各协议栈模块库（Wi-Fi、LTE、Internet Stack） | `ns-3-model-library.pdf` |
| **安装** | 各平台安装步骤 | `ns-3-installation.pdf` |
| **辅助** | 仿真理论、对比、综述 | `Network Simulation and its Limitations.pdf` / `Network_Simulation_Tools_Survey.pdf` / `Network Simulations with the ns-3 Simulator.pdf` |

## 版本说明

本地收录了 ns-3 的 **3.34 / 3.40 / 3.41** 三个版本的 manual/tutorial。推荐：

- **首选 3.41**：最新文档（`ns-3-manual.pdf` 即 3.41 的同义副本）
- 保留 3.34 / 3.40 便于对照旧代码库（如 Aqua-Sim-NG 的早期分支通常绑定特定 ns-3 版本）

## 推荐阅读顺序（零基础 → 能动手）

```
1. ns-3-installation.pdf        ← 先跑通环境（配合 [[ns3-installation-guide]]）
2. ns-3-tutorial-3.40.pdf       ← 入门 6 章：scratch / first.cc / tracing / logging
3. ns-3-manual-3.41.pdf         ← 核心 §事件调度 §Object / §Attribute / §Tracing
4. ns-3-model-library.pdf       ← 按需查阅：对 UWAnet 重要的是 §Internet Stack / §Mobility
5. 辅助综述（可选）
```

## 对 UWAnet 的重点章节

| 章节 | 用途 | 对应里程碑 |
|------|------|-----------|
| Tutorial §2-3 | scratch/ 下第一个脚本 | M1 |
| Manual §Events & Scheduler | 理解 DES 事件调度 | M2 |
| Manual §Object Model | 理解 ns-3 智能指针与继承层次 | M2 |
| Manual §Attributes | 配置 MAC 参数（如 backoff 边界） | M3 |
| Manual §Tracing | 收集 benchmark 指标 | M4 |
| Model Library §Mobility | 节点移动模型（WG/AUV/UG） | M3+ |
| Model Library §Internet Stack | IPv4/L3/L4 参考 | 进阶 |

## 辅助文档摘要

- **Network Simulations with the ns-3 Simulator** — ns-3 设计哲学与局限性，适合入门前建立心智模型
- **Network Simulation and its Limitations** — 仿真 vs 实测的差距分析
- **Network Simulation Tools Survey** — ns-3 与 OPNET、OMNeT++、OPNET 的横向对比

## 不推荐深读的内容

ns-3 manual 总共几百页，以下章节可按需再翻：

- Python bindings（UWAnet 不使用）
- NetAnim 图形动画（M4 再看）
- Wi-Fi/LTE 详细建模（与水声信道无关）

## 相关页面

- [[ns3-installation-guide]] — 先搭环境
- [[aqua-sim-family]] — 基于 ns-3 的水声仿真器
- [[uwanet-brainstorm]] — 项目选型依据
- [[dashboard]]

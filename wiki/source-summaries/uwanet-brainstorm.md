---
type: source-summary
source_type: note
created: 2026-04-13
updated: 2026-04-13
tags: [调研, MAC协议, ns-3, Aqua-Sim-NG]
---

# 水声组网协议仿真前期调研

> **原始文件**: `raw/notes/protocol-sim-brainstorm.md`（288行）+ `raw/notes/uwanet-moc-v1.md`

## 核心结论

1. **仿真平台选型**：Aqua-Sim-NG (ns-3) + MATLAB 信道模型
2. **入门路线**：MAC 层协议优先（Slotted ALOHA → FAMA → MACA-U）
3. **物理层复用**：UWAcomm 已有 6 种体制（OFDM/DSSS/FH-MFSK 等）直接接入
4. **环境要求**：Ubuntu 20.04 + ns-3.36 + Aqua-Sim-NG

## 协议栈架构

```
应用层 — 数据采集、任务调度
传输层 — UWAN-TCP / ALOHA-Q
网络层 — VBF / DBR / EEDBR
MAC层  — FAMA / MACA-U / T-LOHI  ← 入门重点
物理层 — ← UWAcomm
信道   — 多径、多普勒、高延迟
```

## MAC 协议分类

| 类型 | 协议 | 特点 |
|------|------|------|
| 竞争型 | ALOHA / Slotted ALOHA | 简单，碰撞多 |
| 握手型 | FAMA / MACA-U | RTS/CTS，适合高延迟 |
| 调度型 | TDMA / T-LOHI | 需要同步 |

## 技术路线

| 阶段 | 工具 | 重点 |
|------|------|------|
| 物理层 | MATLAB (UWAcomm) | 已完成，复用 |
| MAC 层 | Aqua-Sim-NG | Slotted ALOHA → FAMA |
| 网络层 | Aqua-Sim-NG | VBF / DBR 路由 |
| 跨层 | ns-3 + MATLAB | 信道驱动自适应 |

## 相关页面

- [[dashboard]]

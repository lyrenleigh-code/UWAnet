---
type: source-summary
source_type: paper
created: 2026-04-21
updated: 2026-04-21
tags: [Aqua-Sim, Aqua-Net, 仿真器, ns-3, 水声网络, 架构]
---

# Aqua-Sim 家族 — 水声网络仿真器演进

> **原始资料**：
> - `raw/papers/Aqua-Net_An_underwater_sensor_network_architecture_Design_implementation_and_initial_testing.pdf` — Peng et al. (UConn, 2009 MTS/IEEE OCEANS)
> - `raw/papers/Aqua-Sim_Fourth_Generation_Towards_General_and_Intelligent_Simulation_for_Underwater_Acoustic_Networks.pdf` — Guo et al. (Jilin U., 2025 IEEE IoT Journal, preprint)

## 家族谱系

```
Aqua-Net (2009, UConn)      ← Aqua-Sim 的前身，ns-2 上的协议栈
      │
Aqua-Sim (FG, ns-2-based)   ← 第一代，面向对象重构
      │
Aqua-Sim-NG (ns-3-based)    ← 第二代，智能指针、模块化管理
      │
Aqua-Sim-TG (半物理)         ← 第三代，集成 Bellhop + 真实 modem
      │
Aqua-Sim-FG (2025)          ← 第四代，MATLAB + C++ + Python 混合
                              https://github.com/JLU-smartocean/aqua-sim-fg
```

历史下载量：前三代合计 7000+ 次（Guo et al. 2025）。

## Aqua-Net 架构亮点（2009 经典）

Peng et al. 提出 UWSN 专用协议栈架构，核心创新：

### 1. 下移 "Narrow Waist"

互联网的 narrow waist 是 IP；无线传感网是 SP（Sensor Protocol）。Aqua-Net 把 narrow waist **降到物理层之上**，称作 USP（Underwater Sensor Protocol）：

```
Application (User 层)
   ↓ Pseudo-BSD Socket
Network Layer (VBF / VBVA / AODV)
   ↓
Link / MAC Layer (UW-Aloha / R-MAC / FAMA / SDRT)
   ↓
USP（narrow waist，抽象 modem 差异）
   ↓ NMEA Serial Comm
Physical Wrapper（Micro-modem / Benthos / OFDM modem）
```

### 2. Cross-Layer Interface + System Database

所有层共用一张"系统数据库"，任意层可查/设参数（如路由层询问物理层支持的功率等级，实现能量感知路由）。避免严格分层丢失跨层优化机会。

### 3. UW-Aloha 案例（MAC）

在 Aqua-Lab 测试床实现并验证：
- 传统 Aloha 在水声环境无法做碰撞检测（声速慢导致传播延迟大）
- UW-Aloha 引入 **ACK 机制**：发 → 等 ACK → 超时 backoff 或重传
- 两种 backoff：**BEB**（二进制指数）vs **PB**（泊松）
- 实测：80 bps modem 上，BEB 吞吐 11.5 bps（14.4% 利用率），PB 10.5 bps（13.1%）；BEB 比 PB 激进，性能更好
- 理论：用马尔可夫链推导 `Pc`，与实测吻合

### 4. 硬件实现

Gumstix (Marvell PXA270, 400 MHz, 64MB RAM) + Embedded Linux；协议栈运行在 user space，与内核解耦。

## Aqua-Sim FG 新特性（2025）

Guo et al. 在 Aqua-Sim-NG 基础上做六大扩展，解决三个痛点：

| 痛点 | 方案 |
|------|------|
| 网络/通信分离仿真 | MATLAB + C++ 混合编程（通过 MATLAB Runtime + CMakeLists.txt 链接 `.so`） |
| AI 方法不支持 | 把 C++ UAN 封装为 Python 包（`cppyy` 绑定），RL agent 可直接调用 ns-3 节点 |
| 配置粗粒度 | 6 新特性（见下） |

### 节点级 3 新特性

1. **Mobility 模型**：UG（水下滑翔机 zigzag）/ WG（波浪滑翔机 + WaveUtil 模型）/ AUV（预设航迹 text 驱动）
2. **自适应 header**：分 public + private header，按包类型动态调整长度，减少传输延迟
3. **Cross-layer Trailer**：跨层参数通过 trailer 字段传递，跨层不跨节点

### 通信级 3 新特性

1. **Subcarrier-level 频谱配置**：不再只配子信道数量，可配子载波数/间隔/保护间隔
2. **多调制模式**：BPSK / QPSK / 8QAM / 16QAM / 64QAM，按 SNR/BER 自适应
3. **多传播模型**：RangePropagation / ThorpPropagation / BellhopPropagation（Thorp 衰减公式 + Bellhop 海洋环境）

### 版本依赖

- Aqua-Sim-TG 绑定 ns-3.27
- **Aqua-Sim-FG 绑定 ns-3.38**

## 对 UWAnet 的启示

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 仿真器 | **Aqua-Sim-NG**（ns-3-based） | TG/FG 较新但学习曲线陡；NG 社区沉淀最稳（[[uwanet-brainstorm]] §选型） |
| 物理层集成 | UWAcomm (MATLAB) ↔ Aqua-Sim | 若后续升级到 FG，MATLAB-C++ 混合已有范式 |
| MAC 路线 | UW-Aloha 起步 → Slotted FAMA | 对应 [[slotted-fama-mac]] |
| 路由路线 | VBF / AODV | Aqua-Net 已原生支持 |
| 跨层设计 | 学习 Trailer 机制 | FG 的 trailer 是好范本 |

## 关键局限（Aqua-Net 原文）

> "None of the aforementioned MAC protocols have been implemented or tested in a real underwater testbed."（2009）

2009 年论文时，大多 MAC 协议只有仿真、没有实测。这是 UWAnet 项目可以继续拓展的方向（若将来接上 UWAcomm 的信道数据甚至真实 modem）。

## 相关页面

- [[slotted-fama-mac]] — Aqua-Net 提到 FAMA，本页详解 Slotted 变种
- [[janus-standard]] — NATO 水声通信标准，可作 baseline PHY
- [[ns3-documentation-index]] — 仿真器底座
- [[uwanet-brainstorm]] — 选型决策
- [[uwanet-moc-v1]] — 项目总览
- [[dashboard]]

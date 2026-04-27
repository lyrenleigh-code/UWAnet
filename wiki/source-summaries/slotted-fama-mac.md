---
type: source-summary
source_type: paper
created: 2026-04-21
updated: 2026-04-21
tags: [MAC协议, Slotted-FAMA, RTS-CTS, 水声网络, 握手型MAC]
---

# Slotted FAMA — 水声网络 MAC 协议

> **原始资料**：`raw/papers/Molins+和+Stojanovic+-+2006+-+Slotted+FAMA+a+MAC+protocol+for+underwater+acoust.pdf`
>
> Molins & Stojanovic（MIT Sea Grant College Program, 2006 OCEANS Asia Pacific）

## 核心贡献一句话

**把 FAMA 的"长 RTS/CTS"槽化掉**，用时隙消除异步性，既保留碰撞避免能力，又不浪费能量。

## 背景：传统 MAC 在水声信道的困境

| 协议 | 原理 | 水声环境问题 |
|------|------|-------------|
| CSMA | 听信道再发 | 声速慢，"听不见"≠"没发"，虚空闲 |
| MACA (Karn) | RTS/CTS 握手，无 CS | 隐藏/暴露终端仍会碰撞（见 Fig.3）|
| MACAW (Bharghavan) | + 自适应 backoff + ARQ | 同上 |
| FAMA (Fullmer & G-L-Aceves) | MACA + CS，**RTS 长度 > 最大传播延迟** | 传播延迟 1 秒/1.5 km → 控制包过长，能耗极高 |

**水声信道关键参数**：传播时延 `Tprop ≈ 1 s / 1.5 km`，带宽 `< 10 kbps`，BER 高，链路质量差。

## Slotted FAMA 设计

### 槽长定义

```
T_slot = T_max_prop + γ_CTS
```

其中 `γ_CTS` 是 CTS 包传输时间。可选加入 `guard time` 吸收时钟漂移。

### 协议流程（一次成功握手）

```
t=0        A 发 RTS          （slot n 起点）
t=slot     B 收到 RTS，slot n+1 起点发 CTS
t=2·slot   A 收到 CTS，slot n+2 起点发 DATA
...        DATA 占 T_data（多 slot）
t+T_data   B 收到完整 DATA，下一 slot 发 ACK/NACK
```

所有控制包（RTS/CTS/ACK/NACK）**必须在 slot 起点开始发**。

### 节点状态机

```
Idle                                           ← 初始
  │  listen channel
  │  有包 & 无载波 → 发 RTS
  ↓
Sending RTS
  │  wait 2 slots for CTS
  │   ├── 收到 CTS → 下一 slot 发 DATA
  │   └── 无 CTS   → Backoff
  ↓
Backoff (random slots)
  │  backoff 期间如听到 CTS → 进入 Receiving
  │  backoff 期满 → 重发 RTS（不重置计时器）
  ↓
Receiving
  │  依包类型决定等待时长：
  │   xRTS       → 等 2 slot（给目标发 CTS + 自己 DATA 起始）
  │   xCTS       → 等 T_data + ACK
  │   xDATA      → 等 ACK/NACK
  │   xACK       → 等到 slot 结束
  │   xNACK      → 等一个完整 DATA + ACK 长度
  │   干扰/碰撞  → 按最坏情况（等同 xCTS）
```

### 优化 1：不重置 Backoff 计时器

**原始 FAMA 问题**：进 Backoff → 被打断进 Receiving → 回 Backoff 时重置 → 死循环。

**Slotted FAMA 改进**：Backoff 时间只在"RTS 未收到 CTS"时设定一次；被打断回来继续计时，不重置。

### 优化 2：Transmission Priority

刚接收完包的节点，如果队列有包，**立即发 RTS 不进 Backoff**。有助于多跳路径上的包快速流转、公平性提升。

### 优化 3：Trains of Packets

站点本地队列可一次性打包发给同一目的地的连续数据包。但 FAMA 的"最大包时长"约束仍在，所以每个 DATA 单独确认（不合并 ACK）。

### 优化 4：ACK 重引入暴露终端问题

原始 FAMA 只防 CTS 冲突；加 ACK 后邻居 C 必须等源节点 B 收到 A 的 ACK，**沉默期从 `T_data` 扩展到 `T_data + T_ACK`**。这是 ARQ 的代价。

## 吞吐分析（作者推导）

网络布局：节点 `w` 有 `N` 个邻居，每个邻居又有 `Q` 个对 `w` 隐藏的邻居。

关键公式（N 邻居对称、Poisson 到达）：

```
Ps = exp(-λ(N+Q)·T_slot)              # 无碰撞概率
P_e = 1 - (1 - BER)^L                 # 长 L 位数据包差错率
T_fail = 2·T_slot·(1 - Ps) / (N+1)    # 失败周期
T_success ∝ RTS + CTS + T_data + ACK  # 成功周期
S = U / (I + B)                       # 单节点吞吐
```

## 仿真验证（Matlab/Simulink）

| 参数 | 值 |
|------|---|
| 区域 | 25 km²，16 cell |
| 节点数 | 16 AUV，每 cell 一个 |
| 移动性 | 2.5 m/s，方向 1-5 min 随机变化 |
| DATA 长度 | 3000 bits |
| 控制包长度 | 100 bits |
| 比特率 | 1000 bps |
| 到达过程 | Poisson，平均 1 包 / 300 s |

结论：存在**最优发射功率**（过高→邻居多→碰撞多；过低→隐藏终端多→重传多）。

## 对 UWAnet 的使用价值

### M3 里程碑直接对标

[[uwanet-moc-v1]] 的 MAC 路线：Slotted ALOHA → **Slotted FAMA** → MACA-U。本文是 **M3 实现自定义 MAC 的主要蓝本**。

### 可机器判的成功标准

- RTS/CTS/ACK 时序图与论文 Fig.4 一致
- 节点状态机覆盖 5 种 `x*` 旁听场景
- 仿真结果存在最优功率点（throughput vs tx power 呈单峰曲线）
- 吞吐上界与公式 (2) 吻合（±10%）

### 实施风险

- ARQ 引入暴露终端 → 吞吐上界低于原始 FAMA
- Guard time 必须测环境再定，过短→时钟漂移碰撞，过长→浪费槽位
- 多跳场景论文只给仿真，未给分析式，需自己验证

## 相关页面

- [[aqua-sim-family]] — Aqua-Net 已有 FAMA 变种实现可参考
- [[uwanet-moc-v1]] — 里程碑路线
- [[uwanet-brainstorm]] — MAC 协议分类（握手型）
- [[dashboard]]

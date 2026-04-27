---
type: source-summary
source_type: paper
created: 2026-04-21
updated: 2026-04-21
tags: [JANUS, 水声通信标准, NATO, FH-BFSK, 互操作]
---

# JANUS — NATO 水声通信标准

> **原始资料**：`raw/papers/Potter+等+-+2014+-+The+JANUS+underwater+communications+standard.pdf`
>
> Potter et al. (NATO CMRE + Teledyne Benthos + WTD 71 + Ocean Sensors, 2014 UComms)

## 核心贡献一句话

**首个开放式水声通信标准**，规定物理层+MAC，支持异厂商 modem 互操作，军民两用，公开可实施。

## 动机

- 水声 modem 市场**完全私有化**：各厂用各自的调制方式/封包格式，**无法互通**
- 海上运营方越来越需要整合异构装备（不同潜器、浮标、固定站），必须有协议栈互操作能力
- 现有任何两台 modem 之间**连发现彼此都做不到**，更谈不上自组网

## 物理层：FH-BFSK

选择 **Frequency-Hopped Binary FSK**，理由：**粗糙海洋信道下最鲁棒** + 实现简单（模拟 D 类功放就能做，甚至不需要调幅）。

### 符号结构

- 13 对正交频隙，每对对应一个 FH 序号
- 带宽 `Bw ≈ Fc / 3`（±10%）
- 频隙宽度 `FSw = Bw / 26`
- 基线 chip 时长 `Cd = 1 / FSw`（Cd 可翻倍：1,2,4,8×Cd 以换更鲁棒/检测率，代价是降速）
- 0/1 比特决定选 FH 对中的哪一个频点

### 初始频段（Baseline）

```
Fc  = 11520 Hz
Bw  = 4160 Hz
FSw = 160 Hz
Cd  = 6.25 ms
```

### 信道编码

- 1/2 卷积码，约束长度 k=9，生成多项式 `g1(x)=x^8+x^7+x^5+x^3+x^2+x+1`, `g2(x)=x^8+x^4+x^3+x^2+1`
- 数据末尾加 8 零比特 flush → 64+8=72 输入 → 144 符号输出
- 交织深度 13（突发错误→多个分散单错，提高解码概率）
- 8-bit CRC（CCITT 多项式 `x^8+x^2+x+1`）

### 同步前导

固定 32 chip 伪随机序列（`01101011110001001101011110001 00`，31 bit PN）。

### 可选 Wake-up Tones

3 个频点连续发送（`Fc-Bw/2`, `Fc`, `Fc+Bw/2`），每个持续 `4·Cd`，结束后 0.4 s 静默再发主前导。用于唤醒低功耗 modem。

## 基线包（Baseline JANUS Packet）

**64 bit** 固定格式，其中 34 bit 应用数据块（ADB）由用户自定义：

| 位 | 字段 | 说明 |
|---|------|------|
| 1-4 | Version | 当前版本 3（`0011`） |
| 5 | Mobility | 0 静止 / 1 移动 |
| 6 | Schedule | 0 off / 1 on（开启时 ADB 前 8 bit 作为预留或重复间隔） |
| 7 | Tx/Rx | 0 仅发 / 1 收发 |
| 8 | Forward | 0 / 1，用于路由和 DTN |
| 9-16 | Class ID | 256 用户类别（国家/组织） |
| 17-22 | App Type | 64 种应用类型/类别 |
| 23-56 | ADB | 用户定义 34 bit |
| 57-64 | CRC | 上述 56 bit 的 8-bit 校验 |

### 应用类别（示例）

- 0 紧急
- 1 Underwater GPS
- 2 Underwater AIS
- 3 Pinger（测距）
- 15 Capabilities Descriptor
- 16 NATO JANUS 参考实现
- 17-210 各国（按字母顺序分配）
- 232-238 固定设施（钻井、波浪/风/太阳能发电等）
- 255 JANUS special

### 可选 Cargo Payload

基线包后可直接附载荷，无间隙。位 6=1 + 位 23=0 + 位 24-30 指定预留时长（通过公式 1）可以保留信道不发具体数据（用于紧急信道预留，最多 10 分钟）。

## MAC 层：CSMA/CA + BEB + GA

默认 MAC 是 **带全局感知（Global Awareness）的 CSMA/CA 二进制指数退避**：

### 信道占用判据

- 发送前对全 JANUS 带宽做 `352·Cd` 的背景能量估计
- 后续每 `16·Cd` 窗口对比背景
- **高于背景 3 dB 即判忙**

### BEB 退避

```
节点侦测忙 → 计数 C（初始 1）
              ↓
每槽 slot_len = 176·Cd 计一次
D = 2^(C-1)
下一 slot 以概率 1/(D+1) 发送
若忙则 C += 1（每 slot 最多加 1 次）
C_max = 8
发送后 C 重置为 1
C 达 8 → 丢弃本次
```

## 与 Slotted FAMA / UW-Aloha 对比

| 项 | JANUS | UW-Aloha | Slotted FAMA |
|----|-------|----------|-------------|
| 调制 | FH-BFSK 固定 | 任意（UWAcomm 可选 OFDM/DSSS/FSK） | 任意 |
| MAC 类型 | CSMA/CA + BEB | Aloha + ACK + BEB | RTS/CTS + 时隙 + ACK |
| 握手 | 无 | 无 | 有（RTS/CTS） |
| 标准化 | **有**（NATO STANAG in progress） | 无 | 无（学术） |
| 适用 | 广播、发现、低速互操作 | 低负载 | 中等负载、有隐藏终端 |

## 对 UWAnet 的使用价值

### 作为 Baseline 物理层

JANUS **物理层参数完全公开**，可直接在 UWAcomm 里实现一份 JANUS-compliant FH-BFSK 调制解调器，作为 MAC 层仿真的标准 PHY。

### 作为 MAC 对比基准

JANUS 的 CSMA/CA+BEB 与 UW-Aloha 的纯 Aloha+ACK 形成对比：
- 相同信道下，JANUS 的载波感知应能降低碰撞
- 但 BEB 退避槽 `176·Cd ≈ 1.1 s` 可能在稀疏网络浪费时间

### 作为互操作层

如果 UWAnet 未来接入真实 modem（Teledyne Benthos 等），JANUS 是**唯一**与异厂商互通的桥梁。

## 信息密度

仅 64 bit 基线包 → 吞吐极低（约 **80 bps 的 1%~3%**），定位是**通知/发现**，不是大数据。大数据走 cargo payload。

## 相关页面

- [[aqua-sim-family]] — Aqua-Net 未明确支持 JANUS，是 UWAnet 可扩展点
- [[slotted-fama-mac]] — 另一主流 MAC，学术派
- [[uwanet-brainstorm]] — 物理层/MAC 选型讨论
- [[uwanet-moc-v1]] — 里程碑规划
- [[dashboard]]

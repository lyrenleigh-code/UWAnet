# 水声通信组网协议仿真 MOC

> 目标：基于 Aqua-Sim-NG (ns-3) 构建水声网络协议仿真平台
> 物理层复用 [[UWAcomm MOC|UWAcomm]] 项目成果（OFDM/DSSS/FSK）
> 前期调研：[[水声通信组网协议仿真笔记|头脑风暴笔记]]
> 项目状态：前期调研阶段

#UWAnet #项目

---

## 协议栈架构

```
┌─────────────────────────────────┐
│        应用层 Application        │  数据采集、任务调度
├─────────────────────────────────┤
│        传输层 Transport          │  UWAN-TCP / ALOHA-Q
├─────────────────────────────────┤
│        网络层 Network            │  VBF / DBR / EEDBR
├─────────────────────────────────┤
│        MAC 层                   │  FAMA / MACA-U / T-LOHI
├─────────────────────────────────┤
│        物理层 Physical           │  ← UWAcomm (OFDM/DSSS/FSK)
├─────────────────────────────────┤
│     水声信道 Acoustic Channel    │  多径、多普勒、高延迟
└─────────────────────────────────┘
```

---

## 技术路线

| 层级 | 仿真工具 | 重点内容 |
|------|---------|---------|
| 物理层 + 信道 | MATLAB ([[UWAcomm MOC|UWAcomm]]) | 已有6种体制，可直接复用 |
| MAC 层 | Aqua-Sim-NG (ns-3) | **入门重点**：Slotted ALOHA → FAMA → MACA-U |
| 网络层 | Aqua-Sim-NG (ns-3) | VBF / DBR 路由协议 |
| 跨层 | ns-3 + MATLAB 联合 | 信道模型驱动的自适应协议 |

---

## 项目结构

| 目录 | 内容 |
|------|------|
| `前期调研/` | 头脑风暴、文献调研、技术选型 |
| `MAC层/` | MAC协议实现与仿真 |
| `网络层/` | 路由协议实现与仿真 |
| `仿真环境/` | ns-3 / Aqua-Sim-NG 环境搭建记录 |

---

## 与 UWAcomm 的关系

```
UWAcomm（物理层算法仿真）          UWAnet（网络协议仿真）
├── OFDM/SC-FDE/SC-TDE ──────────→ PHY 层接口
├── DSSS ─────────────────────────→ 抗干扰物理层
├── FH-MFSK ──────────────────────→ 低速率可靠传输
├── 信道模型 gen_uwa_channel ─────→ 信道仿真参数
└── 多普勒/同步 ──────────────────→ 节点移动性建模
```

---

## 里程碑

| 阶段 | 内容 | 状态 |
|------|------|------|
| M0 | 前期调研与技术选型 | 🔶 进行中 |
| M1 | 环境搭建：ns-3 + Aqua-Sim-NG 跑通 example | ⬜ 待做 |
| M2 | 读懂 aqua-sim-mac-aloha.cc 源码 | ⬜ 待做 |
| M3 | 实现自定义 MAC 模块（简化版 Slotted ALOHA） | ⬜ 待做 |
| M4 | 参数扫描实验 + 性能分析 + 与理论对比 | ⬜ 待做 |

---

## 参考资源

| 类型 | 资源 |
|------|------|
| 教材 | 《水声学原理》汪德昭、《Underwater Acoustic Communications》Stojanovic |
| 通信基础 | Proakis《数字通信》 |
| 顶会期刊 | IEEE JSAC、IEEE TWC、INFOCOM |
| 数据集 | WHOI 水声数据集、UCSB 海试数据 |
| 开源工具 | Aqua-Sim-NG、DESERT Underwater、UnetStack |

---

## Areas 关联

- [[水声通信]] — 水声通信核心技术知识体系
- [[信道建模]] — 物理层信道特性

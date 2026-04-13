# 水声通信组网协议仿真笔记

> 整理自学习对话，涵盖环境搭建、协议构建、理论基础及 Claude Code 加速方案。
> 性质：前期头脑风暴 / 技术摸索文档
> 项目：[[UWAnet MOC|水声通信组网]]
> 物理层基础：[[UWAcomm MOC|UWAcomm 水声通信算法仿真]]
> Areas：[[水声通信]] [[信道建模]]

#UWAnet #前期调研 #头脑风暴

---

## 一、整体技术栈概览

水声网络协议栈与传统网络类似，但每层都有独特挑战：

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
│        物理层 Physical           │  OFDM / DSSS / FSK
├─────────────────────────────────┤
│     水声信道 Acoustic Channel    │  多径、多普勒、高延迟
└─────────────────────────────────┘
```

**入门推荐路线：MAC 层协议 + Aqua-Sim-NG**

---

## 二、仿真平台选择

| 平台 | 特点 | 适用场景 |
|------|------|----------|
| **ns3** | 开源、模块化强、社区活跃 | 网络协议层仿真首选 |
| **MATLAB/Simulink** | 信号处理能力强 | 物理层 + 信道建模 |
| **Aqua-Sim-NG** | ns3 的水声扩展插件 | 水声网络专用仿真 |
| **DESERT Underwater** | ns2/ns3 扩展 | 跨层协议研究 |
| **Python + SimPy** | 灵活、轻量 | 自定义协议快速验证 |

**推荐组合：Aqua-Sim-NG（基于 ns3）+ MATLAB 信道模型**

---

## 三、环境搭建（Step by Step）

### 系统要求

- Ubuntu 20.04 LTS（虚拟机 / WSL2 均可）
- ns-3.36（与 Aqua-Sim-NG 兼容版本）

### 安装依赖

```bash
sudo apt update
sudo apt install -y g++ python3 python3-dev cmake git \
  libsqlite3-dev libxml2-dev libgtk-3-dev \
  python3-matplotlib python3-numpy
```

### 下载并编译 ns-3

```bash
wget https://www.nsnam.org/releases/ns-allinone-3.36.tar.bz2
tar xjf ns-allinone-3.36.tar.bz2
cd ns-allinone-3.36/ns-3.36
```

### 安装 Aqua-Sim-NG

```bash
cd src/
git clone https://github.com/rmartin5/aqua-sim-ng aqua-sim

cd ../
./ns3 configure --enable-examples --enable-tests
./ns3 build

# 验证安装
./ns3 run "aqua-sim-simple"
```

> **常见问题**：编译报错 99% 是 Python 版本问题，确保 `python3 --version` 为 3.8+。

---

## 四、Aqua-Sim-NG 代码结构

```
src/aqua-sim/
├── model/
│   ├── aqua-sim-channel.cc      ← 水声信道（衰减、延迟）
│   ├── aqua-sim-mac-*.cc        ← MAC 层协议实现（核心）
│   ├── aqua-sim-phy.cc          ← 物理层
│   ├── aqua-sim-routing-*.cc    ← 路由层
│   └── aqua-sim-header.cc       ← 数据包头部格式
├── examples/
│   └── *.cc                     ← 仿真脚本入口（从这里改起）
└── helper/
    └── aqua-sim-helper.cc       ← 组网辅助类
```

重点学习文件：`aqua-sim-mac-aloha.cc`

---

## 五、小规模案例：5 节点 Slotted ALOHA 仿真

### 5.1 最快起步方式

```bash
# 复制官方 example 到 scratch 目录
cp src/aqua-sim/examples/broadcastMAC.cc scratch/my-mac-demo.cc

# 编译并运行
./ns3 run "my-mac-demo"
```

### 5.2 关键修改点

```cpp
// 修改节点数
nodes.Create(5);

// 使用 Slotted ALOHA
asHelper.SetMac("ns3::AquaSimMacAloha",
                "SlottedAloha", BooleanValue(true),
                "SlotDuration", TimeValue(Seconds(0.1)));

// 线形拓扑：节点沿 X 轴排列，Z = -50m（水下 50 米）
nodes.Get(i)->GetObject<MobilityModel>()
     ->SetPosition(Vector(i * distance, 0.0, -50.0));

// 仿真时长
Simulator::Stop(Seconds(100.0));
```

### 5.3 自定义 MAC 模块框架

```cpp
// 核心逻辑：带退避的发送
void AquaSimMacMyAloha::SendWithBackoff(Ptr<Packet> pkt) {
    uint32_t slots = (uint32_t)(UniformVariable().GetValue(1, 8));
    double backoff = slots * m_slotDuration.GetSeconds();

    Simulator::Schedule(Seconds(backoff),
                        &AquaSimMacMyAloha::DoSend, this, pkt);
}
```

### 5.4 参数扫描与可视化

```bash
# 批量运行，改变节点数
for n in 3 5 8 10 15; do
    ./ns3 run "my-mac-demo --nodes=$n --simTime=200" >> results.txt
done
```

```python
# 用 Python 绘图
import matplotlib.pyplot as plt
import numpy as np

data = np.loadtxt("results.txt")
nodes, throughput, delay = data[:,0], data[:,1], data[:,2]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4))
ax1.plot(nodes, throughput, 'o-', color='steelblue')
ax1.set_title("Slotted ALOHA 吞吐量")
ax2.plot(nodes, delay, 's-', color='coral')
ax2.set_title("端到端时延")
plt.tight_layout()
plt.savefig("mac_results.png", dpi=150)
```

---

## 六、需要掌握的理论

### 水声物理基础
- 声波传播：Thorp 衰减模型、球面扩展损失
- 多径效应：时延扩展、相干带宽
- 多普勒效应：节点移动导致的频偏
- 噪声模型：Wenz 曲线
- 声速剖面：温跃层、混合层对信道的影响

### 通信理论
- 数字调制与解调（PSK、QAM、OFDM）
- 信道编码（Turbo、LDPC、喷泉码）
- 自适应均衡（LMS、RLS 算法）
- 信息论基础（Shannon 容量）

### 网络协议理论
- 图论（网络拓扑分析）
- 排队论（MAC 层性能分析）
- 博弈论（分布式协议设计）

### MAC 层协议分类

```
竞争类：
  ALOHA → Slotted ALOHA → MACA-U（考虑传播延迟）→ FAMA

预约类：
  TDMA（需精确时间同步）
  CDMA（适合稀疏网络）

混合类：
  ROPA、PCAP、DOTS
```

---

## 七、推荐参考资源

| 类型 | 资源 |
|------|------|
| 教材 | 《水声学原理》汪德昭、《Underwater Acoustic Communications》Stojanovic |
| 通信基础 | Proakis《数字通信》 |
| 顶会期刊 | IEEE JSAC、IEEE TWC、INFOCOM |
| 数据集 | WHOI 水声数据集、UCSB 海试数据 |
| 开源工具 | Aqua-Sim-NG、DESERT Underwater、UnetStack |

---

## 八、用 Claude Code 加速开发

### 时间对比

| 阶段 | 手动开发 | Claude Code 辅助 |
|------|----------|-----------------|
| 环境搭建 | 5~7 天 | 1 天 |
| MAC 模块开发 | 7~10 天 | 2 天 |
| 调试排错 | 3~5 天 | 1 天 |
| 实验分析 | 2~3 天 | 1 天 |
| **合计** | **~4 周** | **~1 周** |

### Claude Code 能做什么

在 ns-3 项目目录下启动 Claude Code，直接用自然语言描述需求：

```bash
# 在 ns-allinone-3.36/ns-3.36/ 下启动
claude

# 示例指令：
> 帮我在 src/aqua-sim/model/ 下创建一个 Slotted ALOHA 的 MAC 模块，
  继承 AquaSimMac 基类，实现 TxProcess 和 RxProcess，
  加上时隙退避逻辑和重传计数器，参数通过 TypeId 注册

> 编译报错了，帮我看：[粘贴报错信息]

> 帮我写个 Python 脚本读 CSV，画吞吐量 vs 节点密度的曲线
```

Claude Code 会自动读取现有代码结构，生成 `.h` 和 `.cc` 文件，并修改 `CMakeLists.txt` 注册模块。

### Claude Code 压不了的时间

理解仿真结果背后的原因仍需自己掌握理论。例如：节点数增加但吞吐量下降，需要判断是正常的碰撞加剧，还是退避参数设置有误。**工具加速写代码，理论理解无法跳过。**

### 推荐起步方式

1. 安装 Claude Code（`npm install -g @anthropic-ai/claude-code`）
2. 在 ns-3 项目目录下执行 `claude`
3. 先让它解释一个现有文件（如 `aqua-sim-mac-aloha.cc` 的 `TxProcess` 函数），确认能正常读取代码
4. 再逐步推进模块生成和仿真脚本编写

---

## 九、学习路线（1 个月版）

| 阶段 | 内容 | 时间 |
|------|------|------|
| Week 1 | 装好环境，跑通 Aqua-Sim-NG 自带 example | 3~5 天 |
| Week 2 | 读懂 `aqua-sim-mac-aloha.cc` 源码，改参数跑实验 | 3~5 天 |
| Week 3 | 仿照写自己的 MAC 模块（简化版 ALOHA） | 5~7 天 |
| Week 4 | 参数扫描实验 + Python 画图 + 与理论公式对比 | 3~5 天 |

**用 Claude Code 可将上述整体压缩至约 1 周。**

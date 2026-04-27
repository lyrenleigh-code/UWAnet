---
type: plan
created: 2026-04-21
updated: 2026-04-27
tags: [roadmap, 里程碑, UWAnet, 规划]
---

# UWAnet 路线图

> 对齐 [[specs/active/M0-charter.md]] §成功标准,每个里程碑含 **目标 / Exit Criteria /
> 依赖 / 预估工时**。工时区间含下界(AI 辅助、理想状态)与上界(踩常见坑、需要人工介入)。
>
> **Exit Criteria 硬约束**:每条**必须**由 **具体命令 / 文件路径存在检查 /
> grep 命中数 / 数值阈值 / exit code** 五类之一判定;**禁止散文化要求**
> (如"回答两问 / 理解透 / 讨论清晰")。

---

## M1: 环境基础与 smoke test(Environment & Boot)

### 目标

在 WSL2 Ubuntu 22.04 内搭好 ns-3.41 + Aqua-Sim-NG 编译环境,跑通一个官方
`hello-simulator` / `aqua-sim-mac-aloha` example 产生非空日志。
(2026-04-21 dry-run 已实测装机 2015/2015 编过,本里程碑等价于在主仓侧复刻。)

### Exit Criteria

1. `src/setup/install_ns3_aquasim.sh` 存在且可 `bash -n` 语法检查通过,包含
   `apt-get` / `git clone` / `cmake` / `make` 关键词(对齐 dry-run 实测脚本)。
2. `./ns3 run hello-simulator` 退出码 0,stdout 至少打印 `Hello Simulator` 字样;
   `./ns3 run JmacTest` 或 `./ns3 run broadcastMAC_example` 退出码 0。
3. `tests/smoke/test_aqua_sim_aloha.py` 以退出码 0 结束,标准输出含
   `packets_sent` 与 `throughput`(单位 **bps**)两个键。
4. `workflows/01-env-setup.md` ≥ 30 行,`grep -l "ns3-installation-guide\|aqua-sim-family"`
   同时命中两个 source-summary 引用。

### 依赖

- **外部**:Windows 11 + WSL2 可用;国内网络下 ns-3 源/apt 源可达(BFSU/USTC 镜像)。
- **内部**:无前置里程碑。
- **知识**:[[wiki/source-summaries/ns3-installation-guide]]、
  [[wiki/source-summaries/aqua-sim-family]] §版本依赖。

### 预估工时

- 下界:**1 天**(AI 辅助、无网络故障)。
- 上界:**3 天**(首次 WSL2 迁移盘 + Hyper-V 冲突 + GCC `-Werror=parentheses` 等坑)。
- 参考:[[raw/notes/protocol-sim-brainstorm.md]] §八 手动开发 5-7 天 vs Claude Code 1 天。

---

## M2: 读懂 Aqua-Sim-NG MAC 源码 + UWAcomm 接口 v0(Code Reading & Interface)

### 目标

阅读 `src/aqua-sim/model/aqua-sim-mac-aloha.cc` 的 `TxProcess` / `RxProcess`
主循环,产出注释版源码与调用序列图;同步定义 UWAcomm → ns-3 的 PHY trace
文件接口 v0(JSON schema + 样例)。

### Exit Criteria

1. `wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` 存在且满足
   `grep -c "^### " wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` ≥ 3
   (至少 3 个三级小节,对应 `TxProcess` / `RxProcess` / `HandleTimeout` 三关键函数),
   并 `grep -c '```mermaid' wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` ≥ 1
   (至少 1 个 Mermaid 图)。
2. `specs/active/phy-trace-schema.md` 存在,且 `grep -cE "^\s*\"(timestamp_s|snr_db|ber|modulation|node_id)\"" specs/active/phy-trace-schema.md` ≥ 5
   (JSON schema 5 个必填字段全命中);且 `grep -c "UWAcomm" specs/active/phy-trace-schema.md` ≥ 1
   (明示 UWAcomm 侧需新增 `jsonencode` 导出能力,见 [[plans/risks.md]] §R-X1)。
3. `tests/trace/test_phy_trace_load.cc` 存在,编译后执行退出码 0;源码内
   `grep -cE "assert.*(ber|snr_db)" tests/trace/test_phy_trace_load.cc` ≥ 2
   (至少 2 条对 `ber ∈ [0, 0.5]`、`snr_db ∈ [-10, 40]` 的断言)。
4. `wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` §事件调度 小节存在
   (`grep -n "^### 事件调度" wiki/explorations/aqua-sim-mac-aloha-walkthrough.md`
   命中 1 行),且该文件包含关键词 `Simulator::Schedule` 或 `Timer::Schedule`
   (`grep -cE "Simulator::Schedule\|Timer::Schedule" wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` ≥ 1);
   并存在 §隐藏终端 小节(`grep -c "^### 隐藏终端\|^### Hidden Terminal" wiki/explorations/aqua-sim-mac-aloha-walkthrough.md` ≥ 1)。

### 依赖

- **前置**:M1(需要可编译的 Aqua-Sim-NG 源码树)。
- **跨项目**:[[D:/Claude/TechReq/UWAcomm/wiki/index.md]] 的物理层模块必须可生成
  SNR/BER 序列(modules/13 端到端测试已有类似输出)。
- **知识**:[[wiki/source-summaries/ns3-documentation-index]] §Manual §Events
  & Scheduler、§Attributes。

### 预估工时

- 下界:**2 天**(AI 导读,直接看懂 `aqua-sim-mac-aloha.cc`)。
- 上界:**5 天**(首次接触 ns-3 智能指针、`TypeId` 系统)。

---

## M3: Slotted ALOHA 自定义 MAC + Slotted FAMA 实现(Custom MAC Family)

### 目标

在 `src/aqua-sim/model/` 下新增两个 MAC 模块:**AquaSimMacMyAloha**(带时隙退避
的 Slotted ALOHA)与 **AquaSimMacSlottedFama**(RTS/CTS + 槽化 FAMA)。两者
通过 `TypeId` 注册、可通过 `AquaSimHelper.SetMac()` 挂载;MACA-U 作为 v1.5
可选扩展。**M3 阶段 PHY trace 允许随机占位**(高斯/log-distance 默认),M4 才
强求真实 UWAcomm trace。

### Exit Criteria

1. `src/aqua-sim/model/aqua-sim-mac-myaloha.h`、`aqua-sim-mac-myaloha.cc`、
   `aqua-sim-mac-slottedfama.h`、`aqua-sim-mac-slottedfama.cc` 4 个文件存在
   (`ls` 全部命中),`./ns3 build` 退出码 0。
2. `tests/mac/test_myaloha_5nodes.cc` 与 `test_slottedfama_5nodes.cc` 各
   运行 100 s 仿真,退出码 0,输出行含 `throughput_bps > 0` 且 `pdr > 0`
   (`grep -E "throughput_bps=[1-9]" <stdout>` 与 `grep -E "pdr=[0]\.[1-9]\|pdr=1\." <stdout>` 均命中)。
3. `grep -cE "Sending RTS\|Backoff\|Receiving\|xCTS\|xDATA" src/aqua-sim/model/aqua-sim-mac-slottedfama.cc`
   ≥ 5(对齐 [[wiki/source-summaries/slotted-fama-mac]] §节点状态机 5 种 `x*` 旁听场景)。
4. `workflows/02-custom-mac.md` 存在,且
   `grep -cE "CMakeLists.txt\|TypeId::SetParent\|NS_OBJECT_ENSURE_REGISTERED" workflows/02-custom-mac.md`
   ≥ 3(增量修改清单的 3 个关键 artifact 全部被文档提及)。
5. 吞吐数值验证:`scripts/m3_verify_fama.py` 退出码 0,内部断言 Slotted FAMA
   实测吞吐 vs 公式 (2) 推算上界相对误差 ≤ 0.15(15%;对齐
   [[wiki/source-summaries/slotted-fama-mac]] §可机器判的成功标准)。

### 依赖

- **前置**:M2(需源码结构知识 + PHY trace schema 定义)。
- **跨项目**:无强依赖——M3 PHY 用随机占位,trace 接口开发延后到 M4。
- **知识**:[[wiki/source-summaries/slotted-fama-mac]] §Slotted FAMA 设计、
  [[wiki/source-summaries/aqua-sim-family]] §Aqua-Net UW-Aloha 案例。

### 预估工时

- 下界:**3 天**(MyAloha 直接从 mac-aloha.cc diff,FAMA 用 Claude Code 生成骨架)。
- 上界:**7 天**(FAMA 状态机首版死锁、timer 与事件调度联调、ARQ/ACK 暴露终端
  边界 case)。
- 参考:[[raw/notes/protocol-sim-brainstorm.md]] §八 MAC 模块 AI 辅助 2 天
  vs 手动 7-10 天。

---

## M4: 参数扫描 + 性能评测 + 与理论对比(Benchmark & Compare)

### 目标

对 M3 的两个 MAC(+ Aqua-Sim 自带 ALOHA 作第三 baseline)做三维参数扫描
(节点数 × slot 长度 × 包到达率),产出吞吐/时延/投递率曲线,并与理论
(马尔可夫链 / 公式(2))对比;**首次接入 UWAcomm 真实 trace**(依赖 R-X1 解决);
产出一份**技术报告**回流 Hub。

### Exit Criteria

1. `scripts/benchmark/run_sweep.sh` 与 `scripts/benchmark/plot_results.py` 均存在;
   前者 `bash -n` 语法检查退出码 0,后者 `python -c "import ast; ast.parse(open('scripts/benchmark/plot_results.py').read())"` 退出码 0。
   任选一扫描点(指定 `--seed=42 --mac=slotted-fama --n-nodes=5`)单独复现,
   退出码 0 且产出 `evals/sweep-*/single_point_seed42.csv` 文件。
2. `evals/sweep-2026-MM-DD/results.csv` 存在,`wc -l` ≥ 46(含表头 + ≥ 45 行数据);
   表头列 `head -1` 内含 `mac`、`n_nodes`、`arrival_lambda`、`throughput_bps`、
   `e2e_delay_s`、`pdr` 6 个字段(`awk -F, 'NR==1' | tr ',' '\n' | grep -cE ...` ≥ 6)。
3. `evals/sweep-2026-MM-DD/figures/` 目录下 `ls *.png | wc -l` ≥ 3;且文件名
   含 `throughput`、`e2e_delay`、`pdr` 各 1 个(`ls figures/ | grep -c <关键词>` ≥ 1/每个)。
4. `wiki/comparisons/mac-sweep-2026-MM-DD.md` 存在,且含 §最优区间 与 §理论偏差
   两个三级小节(`grep -cE "^### 最优区间\|^### 理论偏差" <file>` ≥ 2);该文件
   `grep -cE "slotted-fama-mac\|uwanet-brainstorm\|aqua-sim-family" <file>` ≥ 3
   (三个 source-summary 引用全覆盖)。
5. 至少 1 份 Hub 回流文件存在:`ls D:/Claude/Ohmybrain/wiki/{concepts,topics}/*.md`
   中新增至少 1 个与 UWAnet MAC 结论相关的文件(通过文件名含 `uwanet\|mac\|underwater-network`
   的正则匹配,`grep -l` 命中 ≥ 1)。

### 依赖

- **前置**:M3(两个 MAC 实现就绪)。
- **跨项目**:UWAcomm 侧已实装"逐帧/逐包 BER 持久化"导出能力(R-X1 PR 已合并),
  否则 M4 退化为"用 M3 占位 trace 跑 benchmark + 标注 v1 数据"。
- **外部**:无。
- **知识**:[[wiki/source-summaries/slotted-fama-mac]] §吞吐分析,
  [[wiki/source-summaries/aqua-sim-family]] §UW-Aloha 案例实测。

### 预估工时

- 下界:**2 天**(扫描脚本 + 画图 + 结论)。
- 上界:**5 天**(扫描中发现协议 bug 回 M3 修、NetAnim 动画导出问题)。

---

## M5 (Nice-to-have): 网络层路由 + JANUS baseline PHY

### 目标

在 MAC 稳定后扩展到网络层:实现 **VBF(Vector-Based Forwarding)** 或复用
Aqua-Sim-NG 现成 VBF 模块并调参;同时在 UWAcomm 侧加一份 **JANUS-compliant
FH-BFSK** 物理层([[wiki/source-summaries/janus-standard]] §物理层 FH-BFSK),
作为 baseline 与 OFDM/DSSS 做吞吐-鲁棒性对比。

### Exit Criteria

1. `tests/routing/test_vbf_5node_linear.cc` 退出码 0,stdout 行匹配
   `grep -E "pdr=0\.[6-9]\|pdr=1\." <stdout>` 命中(5 节点线形拓扑端到端多跳
   投递率 ≥ 0.60)。
2. `evals/sweep-*/janus_phy/results.csv` 存在且 `wc -l` ≥ 2(表头 + ≥ 1 数据行),
   表头列含 `modulation` 且值集包含 `FH-BFSK`(`grep -c "FH-BFSK" <file>` ≥ 1);
   同时 `diff specs/active/phy-trace-schema.md <(git show HEAD:specs/active/phy-trace-schema.md)`
   为空(trace schema 无破坏性变更,接口向后兼容)。
3. `wiki/comparisons/mac-x-phy-2026-MM-DD.md` 存在且
   `grep -cE "^### " wiki/comparisons/mac-x-phy-2026-MM-DD.md` ≥ 3(至少 3 个
   三级小节,含"MAC × PHY"交叉实验的 设置 / 结果 / 结论)。

### 依赖

- **前置**:M4 benchmark 流程稳定。
- **外部**:UWAcomm 侧有时间加 FH-BFSK 模块(视 UWAcomm todo.md 而定)。

### 预估工时

- 下界:**3 天**。
- 上界:**10 天**(受 UWAcomm 并行进度影响)。
- 风险:详见 [[plans/risks.md]] §R-T3 / §R-X2。

---

## 总工时与临界路径

| 里程碑 | 下界 | 上界 | 前置 |
|--------|------|------|------|
| M1 | 1d | 3d | — |
| M2 | 2d | 5d | M1 |
| M3 | 3d | 7d | M2 |
| M4 | 2d | 5d | M3 |
| M5 | 3d | 10d | M4 |
| **合计(M1-M4)** | **8d** | **20d** | — |
| **含 M5** | **11d** | **30d** | — |

**临界路径**:M1 → M2 → M3 → M4(MAC 家族 benchmark),M5 可与 UWAcomm
的 JANUS 实现并行启动,不阻塞主路径。

## Changelog

- **v1 (2026-04-21)**:dry-run worktree 首次生成,5 个里程碑。
- **v2 (2026-04-21)**:dry-run worktree 响应 `.checkpoint/eval-1.md` 阻断项,
  Exit Criteria 全部从散文化改为 `grep` 命中数/exit code 等机器可判命令。
- **v3 (2026-04-27)**:从 worktree 同步回主仓。删 `goal.yaml.rubric.*` 引用,
  改为对齐 [[specs/active/M0-charter.md]] §成功标准;ns-3 版本表述对齐
  dry-run 实测的 `ns-3.41`(原 3.36 仅是预估);M3/M4 依据 Q4 决策明确
  "M3 PHY 占位、M4 接真实 trace"分阶段策略;M2 EC#2/M4 依赖段对齐
  Q1 决策"UWAcomm 侧需新增 jsonencode 导出能力"。

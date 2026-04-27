---
type: plan
created: 2026-04-21
updated: 2026-04-27
tags: [risks, 风险, UWAnet, 规划]
---

# UWAnet 风险登记

> 对齐 [[specs/active/M0-charter.md]] §成功标准 #6:≥5 条 / 3 大类
> (技术风险 / 外部依赖 / 时间风险)。
> 概率与影响:**H(高) / M(中) / L(低)**。优先级 = 概率 × 影响。
> "需决策"列在 2026-04-27 已逐条裁决,见 §需决策段。

---

## 概览表

| ID | 类别 | 风险 | 概率 | 影响 | 优先级 | 应对策略(摘要) |
|----|------|------|------|------|--------|----------------|
| R-T1 | 技术 | Aqua-Sim-NG 与 ns-3.41 版本漂移 | M | H | HIGH | 锁定 commit hash,先 smoke |
| R-T2 | 技术 | Slotted FAMA 状态机死锁/重传风暴 | M | M | MID | 分阶段实现,加 timeout 警报 |
| R-T3 | 技术 | PHY trace 时间基与 ns-3 事件时间不一致 | M | H | HIGH | schema 强制 `timestamp_s`(simulator-relative),M2 写解析测试 |
| R-T4 | 技术 | UWAcomm BER 粒度(包级)与 ns-3 MAC(帧级)不对齐 | H | M | HIGH | 加 BER→PER 概率转换层,v1 用独立高斯采样近似 |
| R-X1 | 外部依赖 | UWAcomm 侧未实装"逐帧 BER 持久化 + JSON 导出" | M | H | HIGH | M3 用占位 trace 不阻塞;M4 前需 UWAcomm 侧 PR 合并 `export_phy_trace.m` |
| R-X2 | 外部依赖 | JANUS FH-BFSK PHY 未在 UWAcomm todo 里,M5 可能等不到 | M | M | MID | M5 作 Nice-to-have,不阻塞 M1-M4;必要时在 UWAnet 侧写极简 FH-BFSK mock 产 trace |
| R-X3 | 外部依赖 | ns-3 官方 apt 镜像国内访问慢/不稳定 | H | L | MID | 用 BFSU/USTC 镜像;install script 默认走镜像 |
| R-X4 | 外部依赖 | WSL2 在用户环境不可用(Windows 家庭版 / 公司策略禁用 Hyper-V) | L | H | MID | 支持 Ubuntu 虚拟机 / Ubuntu Live USB 回退,在 workflows/01 加章节 |
| R-X5 | 外部依赖 | 上游 Aqua-Sim-NG 与新 GCC 不兼容(`-Werror=parentheses` 类) | M | M | MID | install 脚本加 `CXXFLAGS=-Wno-error` 兜底;dry-run 已实测过 |
| R-M1 | 时间 | M3 Slotted FAMA 上界 7 天被突破 | M | H | HIGH | 设 check-point:7 天内若未跑通 MyAloha → 砍 FAMA 降级为 M4 纯 ALOHA benchmark |
| R-M2 | 时间 | UWAcomm 侧 PR 合并节奏卡 M4 起步 | M | M | MID | M4 启动时若 PR 未合并 → 退化为"用 M3 占位 trace 跑 benchmark + 标注 v1 数据" |
| R-M3 | 时间 | 知识同步拖累主线(每里程碑 wiki 更新压 1-2h) | H | L | MID | 用模板化 wiki 页(`source-summary` / `exploration`),Claude Code 自动生成 |

---

## 明细

### R-T1(技术 · Aqua-Sim-NG 与 ns-3 版本漂移)

- **现象**:[[wiki/source-summaries/aqua-sim-family]] 明确 Aqua-Sim-TG 绑定 ns-3.27、
  Aqua-Sim-FG 绑定 ns-3.38;而 Aqua-Sim-**NG**(rmartin5 fork)未写死版本。
  2026-04-21 dry-run 实测 ns-3.41 + rmartin5/aqua-sim-ng master(shallow clone)
  可 2015/2015 编过,但需 patch `-Werror=parentheses`(见 R-X5)。
- **影响**:编译报错、`./ns3 run` 段错误;浪费 M1 时间。
- **应对**:
  1. M1 install script 锁定 ns-3.41 tag(`--branch ns-3.41 --depth 1`)+
     `rmartin5/aqua-sim-ng` 当前 master(第一次跑通后记录 SHA)。
  2. 若 master 不兼容 → 切到最后一个兼容 tag;无 tag → 降 ns-3 版本。

### R-T2(技术 · Slotted FAMA 状态机死锁)

- **现象**:[[wiki/source-summaries/slotted-fama-mac]] §优化 1 指出原始 FAMA
  的 Backoff 重置会导致死循环;实现时若时序错误可能复现 + 引入新的 `xCTS`/`xDATA`
  等旁听场景漏判。
- **影响**:M3 仿真卡死 / 吞吐反常,可能误判为 bug 消耗数天。
- **应对**:
  1. 先做 MyAloha(简单)再做 FAMA(复杂);FAMA 每个状态转移加 assert + log。
  2. 仿真加 5s watchdog,若 2s 无状态变化 → 抛异常打 checkpoint。
  3. 单元测试覆盖 §节点状态机 5 种 `x*` 场景各一个测试用例。

### R-T3(技术 · 时间基不一致)

- **现象**:UWAcomm JSON trace 的 `timestamp_s` 起点是 MATLAB 侧的仿真时钟(从 0 起),
  ns-3 仿真时钟也从 0 起,但包发送并非在 t=0 对齐;trace 查表需要**相对时钟**而非
  绝对。
- **影响**:查到错误时间点的 BER,仿真结果无物理意义。
- **应对**:
  1. Schema 约定 `timestamp_s` 为"trace 开始后秒数",Phy 在加载时做偏移 `t_phy -
     t_phy_start` 取模 `trace_duration_s` 循环复用,正式化在 `specs/active/phy-trace-schema.md`。
  2. 写 round-trip 测试:MATLAB 产 trace → C++ 加载 → 时间点查询误差 < 1ms。

### R-T4(技术 · BER 粒度不匹配)

- **现象**:UWAcomm 输出的 BER 是端到端比特错误率(每包约 1e-3),但 ns-3 MAC 需要
  **包级丢包概率**(PER)。简单用 PER = 1-(1-BER)^L 只在 IID bit error 下成立。
- **影响**:MAC 吞吐曲线不真,与 [[wiki/source-summaries/slotted-fama-mac]] §公式(2)
  无法直接对标。
- **应对**:
  1. v1:PhyLayer `AquaSimPhy::Receive` 里 `per = 1 - (1-ber)^L`,对小 BER 足够;
     但加警告日志。
  2. v2(M5+):trace schema 扩展加 `per_estimate` 或 `frame_success` 直接字段,由
     UWAcomm 侧按帧决策。
  3. 文档风险点写入 `wiki/comparisons/mac-sweep-*.md` 结论段。

### R-X1(外部依赖 · UWAcomm 端逐帧 BER 持久化)

- **现象**:Q1 决策(2026-04-27)要求 UWAcomm 端到端测试**持久化逐帧/逐包 BER 序列**,
  以保证 MAC 仿真接到的是真实 BER 时序而非合成。但现状是 UWAcomm tests 只 save
  最终均值(典型 MATLAB 测试习惯)。
- **影响**:M4 benchmark 阶段拿不到真实 trace → 无法对比"理论 vs 真实"。
- **应对(2026-04-27 决策更新)**:
  1. **不在本项目侧做合成兜底**:撤销原 v1 应对方案("scripts/uwacomm_bridge/
     从 .mat 均值合成逐帧"),避免误导地把合成数据当真实 baseline。
  2. **走"用户提 PR"路径**:由用户在 UWAcomm 项目侧(独立 session)增加
     `scripts/export/export_phy_trace.m`,逐帧 dump JSON Lines。本项目 agent
     **不**自动改 UWAcomm 源树(对齐 `red_lines.never_touch:
     D:/Claude/TechReq/UWAcomm`)。
  3. **M3 不依赖 R-X1 解决**:M3 PHY 用占位 trace(高斯/log-distance 默认)
     推进 MAC 状态机,M4 启动前等 UWAcomm PR 落地。
  4. **M4 启动时回查**:若 R-M2 触发(PR 未合并)→ 退化为"用 M3 占位 trace 跑
     benchmark + 标注 v1 数据",待 PR 合并后用真实 trace 重跑。

> [!note] 2026-04-27 决策修订
> 本条 v1 应对方案"本项目侧合成桥接 .mat 均值"在 Q1 用户决策后被撤销。
> 决策原文:"我希望要端到端测试是否持久化逐帧/逐包 BER 序列"——明确要求 UWAcomm
> 端实装,不接受合成兜底。

### R-X2(外部依赖 · JANUS PHY 依赖)

- **现象**:[[wiki/source-summaries/janus-standard]] 把 JANUS PHY 列为可选 baseline,
  但 UWAcomm 目前 6 体制不含 JANUS FH-BFSK。M5 Nice-to-have 依赖此项。
- **影响**:M5 延期或砍掉;M1-M4 不受影响。
- **应对**:M5 启动时检查 UWAcomm 侧是否已实现 JANUS;若未实现,用本项目侧极简
  Python 脚本生成一份合规 trace(按 JANUS spec 的 BER 表)即可,不阻塞。

### R-X3(外部依赖 · 国内网络)

- **现象**:`nsnam.org` tarball 与 `gitlab.com/nsnam` 在国内访问不稳;apt 官源同理。
- **影响**:M1 install script 中段失败。
- **应对**:
  1. `install_ns3_aquasim.sh` 默认加 `--use-mirror=bfsu`,`apt` 先换 USTC 源。
  2. 失败 3 次 → fallback 到离线 tarball(要求用户预下载到 `/tmp/`)。
  3. 记录到 [[wiki/source-summaries/ns3-installation-guide]] §常见坑位的升级版本。

### R-X4(外部依赖 · WSL2 不可用)

- **现象**:WSL2 要求 Hyper-V,家庭版/公司受管设备可能被策略禁用。
- **影响**:项目无法在目标主机启动。
- **应对**:
  1. workflows/01-env-setup.md 加"VM 回退路径"章节(VirtualBox + Ubuntu 20.04 ISO)。
  2. CI/Docker 化作为未来选项(暂不做)。

### R-X5(外部依赖 · 上游 Aqua-Sim-NG 与新 GCC 不兼容)

- **现象**:2026-04-21 dry-run 实测 Aqua-Sim-NG 在新 GCC 下触发
  `-Werror=parentheses` 2 处,首轮编译挂 → patch 源码 + `CXXFLAGS=-Wno-error` 修复。
- **影响**:M1 装机首轮失败,需要 ~10 min 排查 + 修补。
- **应对**:
  1. install 脚本预置 `export CXXFLAGS=-Wno-error` 兜底。
  2. 维护一份 `src/setup/aqua-sim-patches/` 收纳已知 patch(若 dry-run worktree
     里有,顺便同步过来)。
  3. 长期:向 rmartin5 上游提 PR 修源码 warning。

### R-M1(时间 · M3 超期)

- **现象**:[[plans/roadmap.md]] M3 上界 7 天。历史参考:[[raw/notes/protocol-sim-brainstorm.md]]
  §八 称手动 7-10 天、AI 辅助 2 天;Slotted FAMA 状态机比 MyAloha 复杂 ~2x,风险
  集中在后半。
- **影响**:M4 benchmark 延期,M5 基本出局。
- **应对**:
  1. M3 切两个半程交付:第 4 天 MyAloha 过 smoke;第 7 天 FAMA 过 smoke。
  2. 第 4 天若 MyAloha 未通 → 请求人工介入。
  3. 预留 buffer:M4 预估工时本身含 1-2 天 slack。

### R-M2(时间 · UWAcomm PR 卡 M4)

- **现象**:R-X1 走 PR 路径,UWAcomm 项目侧的实装节奏不在本项目控制内。M4 启动时
  若 PR 未合并 → 拿不到真实 trace。
- **影响**:M4 退化为"占位 trace + 标注 v1",数据可信度打折扣。
- **应对**:
  1. M3 收尾时(第 6-7 天)主动开启 UWAcomm 侧 session 推 PR。
  2. M4 启动 check-point:若 PR 未合并 ≥ 3 天 → 走退化路径,等 PR 合并后重跑。
  3. 文档明确标注哪批数据是 v1 占位 / 哪批是真实 trace。

### R-M3(时间 · 知识同步开销)

- **现象**:CLAUDE.md 强制 `wiki/index.md` 与 `wiki/log.md` 同步;Stop hook 会拦截。
  每里程碑结束可能触发 1-2h wiki 整理。
- **影响**:冲击工时下界。
- **应对**:
  1. 用模板化 source-summary / exploration 页面(UWAcomm 已有成熟模板)。
  2. Claude Code agent 生成 wiki 首稿,人工只改 2-3 行结论。

---

## 需决策(2026-04-27 已逐条裁决)

| # | 问题 | 决策(2026-04-27) | 触发阶段 |
|---|------|---------|---------|
| Q1 | UWAcomm 端到端测试是否持久化"逐帧"BER,还是只存均值? | **要求 UWAcomm 端实装逐帧持久化**(走 PR 路径,见 R-X1)。**不接受**合成兜底。 | M2 schema 定义 / M4 真实 trace 接入 |
| Q2 | smoke test `throughput` 单位是 bps 还是 pkt/s? | **bps**(用户反问"为什么要提 pkt/s",pkt/s 排除)。stub 现输出 1300.0 bps 不动,results.csv `throughput_bps` 字段对齐。 | M1 |
| Q3 | Aqua-Sim-NG 仓库选 rmartin5 fork 还是 UConn 原作? | **rmartin5/aqua-sim-ng**(按 dry-run 选择)。install 脚本不改,复用真装机经验。 | M1 |
| Q4 | v1 是否要求 UWAcomm trace 真实生成? | **可以先推进**——M3 用随机占位,**M4 才接真实信道**(等 R-X1 PR 合并)。 | M3→M4 过渡 |

---

## 依赖识别检查(对齐 [[specs/active/M0-charter.md]] §成功标准 #7)

- ✅ **UWAcomm**:R-X1, R-X2, R-M2 明确覆盖;[[plans/architecture.md]] §3 有接口表。
- ✅ **ns-3**:R-T1, R-X3, R-X5 覆盖版本 + 网络 + GCC 兼容风险。
- ✅ **Aqua-Sim-NG**:R-T1 覆盖版本漂移;R-X5 覆盖编译警告;
  [[plans/architecture.md]] §6 依赖清单列出。

## Changelog

- **v1 (2026-04-21)**:dry-run worktree 首次生成,11 条风险 / 3 类 / 4 条需决策。
  自检发现 R-X1 与 `red_lines.never_touch` 冲突,已修正为"本项目侧桥接脚本"方案。
- **v2 (2026-04-21)**:dry-run worktree 响应 `.checkpoint/eval-1.md`——
  本文件 v1 得分 15/15(满分),v2 无内容修改,仅补 Changelog 满足 charter
  §成功标准新第 9 条"四份文档末尾含 Changelog"。
- **v3 (2026-04-27)**:从 worktree 同步回主仓 + Q1-Q4 决策落地。
  1. **R-X1 大改**:撤销 v1 "本项目侧合成桥接"方案;改为走"用户提 PR"路径,
     由 UWAcomm 项目侧自行加 `export_phy_trace.m`。本项目 agent 不自动改
     UWAcomm 源树。
  2. **新增 R-X5**:上游 Aqua-Sim-NG 与新 GCC `-Werror=parentheses` 不兼容
     (dry-run 实测 pitfall),install 脚本预置 `CXXFLAGS=-Wno-error`。
  3. **R-M2 改写**:从"Planner token 超支"改为"UWAcomm PR 节奏卡 M4 起步"
     (原 token 超支风险随 worktree 退场而失去意义)。
  4. **§需决策段**:Q1-Q4 全部标"已裁决(2026-04-27)"+ 决策结果。
  5. **顶部 blockquote**:删 `goal.yaml.rubric.risks` 引用,改为对齐
     [[specs/active/M0-charter.md]] §成功标准 #6。
  6. **§依赖识别检查**:删 goal.yaml 引用,改为对齐 charter §成功标准 #7。
  7. **R-T1 / R-T4 中 ns-3 版本表述**:从 3.36 改为 3.41(对齐 dry-run 实测)。

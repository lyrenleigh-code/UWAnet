---
type: exploration
created: 2026-04-21
updated: 2026-04-27
tags: [dry-run, 自主闭环, UWAnet, GAN-harness, ns-3, Aqua-Sim-NG]
---

# UWAnet 自主闭环 Dry-Run 复盘 (2026-04-21)

> 用 UWAnet 重建场景作为 testbed,首次完整跑通"从一行目标到真装机"的自主新建项目
> 闭环工作流。**判定：✅ 完整闭环走通(真装机 PASS)**。
> 本文为 2026-04-27 从 dry-run worktree(`D:/Claude/worktrees/uwanet-redo/`)
> 同步回主仓的复盘记录。
>
> 关联:
> - [[specs/active/M0-charter.md]] §Changelog v3 — 同步说明
> - [[plans/roadmap.md]] §Changelog v3
> - [[plans/architecture.md]] §Changelog v3
> - [[plans/risks.md]] §Changelog v3 + Q1-Q4 决策
> - Hub 方法论:[[D:/Claude/Ohmybrain/wiki/explorations/autonomous-new-project-workflow]]

---

## 背景

执行日期:**2026-04-21**
Worktree:`D:/Claude/worktrees/uwanet-redo/`(独立于主 UWAnet 仓,避免污染调试状态)

用 UWAnet 重建场景验证 `wiki/explorations/autonomous-new-project-workflow.md`
方法论从 Phase 0(一行目标)到 Phase 5(Hub 注册)的真实可行性。

- **目标**:证明 GAN harness + Verification loop 组合能在 ~90 min / $5 预算内
  跑完新建项目 + 真装机
- **结果**:超预算 40%(~75 min / $7),但闭环收敛有效,ns-3.41 + Aqua-Sim-NG
  真装机成功

---

## 累计指标

| 项 | 值 | vs 预算 |
|---|---|---|
| 壁钟时间 | **~75 min** | 90 min 内 ✅ |
| Token 总流量 | **~530k** | 300k 超 77% ⚠️ |
| 美元成本 | **~$7** | $5 超 40% ⚠️ |
| 人工介入次数 | **2** | - |
| Agent 调用次数 | **5**(Planner×2 + Eval×2 + Generator×1)| - |

**token/费用超支主因**:Phase 3 Planner v2 实际触发"rubric 升级后全量扫查"
(从 16 处主动修复),token 124k > 预期 60k。下次开项目 rubric 若升级,预算要先加 50%。

---

## Phase 逐阶段数据

| Phase | 模型 | 时间 | Token | 结果 |
|---|---|---|---|---|
| P1 Scaffold | 人工 dry-run | 2 min | ~5k | 5/5 机器硬门过 |
| P2 Ingest (reuse) | Bash cp | <1 min | <1k | 7 页 wiki |
| P3 Planner v1 | Opus 4.7 | 6.75 min | 97k | 自评 93 |
| P3 Eval v1 | Sonnet 4.6 | 5.7 min | 78k | 独立 **83**(-10 虚报)|
| P3 Rubric v2 升级 | 主会话 Edit | 1 min | ~3k | +4 约束 |
| P3 Planner v2 | Opus 4.7 | 10.8 min | 124k | 自评 95 |
| P3 Eval v2 | Sonnet 4.6 | 4.2 min | 88k | 独立 **92 PASS, Δ+9** |
| P4 Generator | Sonnet 4.6 | 4.3 min | 76k | stub 自检 PASS |
| P4 Evaluator | Sonnet 4.6 | 3.6 min | 61k | 82 FAIL(Bash 权限)|
| P4 真装机 | WSL bash(人工)| ~45 min | - | 2015/2015 编过 |
| P4 demo 验证 | WSL | <1 min | - | hello/Jmac/VBF 全过 |
| P5 Hub diff 准备 | 主会话 | 2 min | ~5k | 等人工 confirm |
| P5 Hub 写入 | 主会话 Edit | 1 min | ~2k | 3 个文件更新 |

---

## 真装机结果

- **WSL 环境**:Ubuntu 20.04.3 LTS(16 核 / 15 Gi RAM / 951G free)
- **安装位置**:`/home/lyren/ns3-workspace/ns-3-dev/`
- **ns-3 版本锁定**:`ns-3.41` tag(shallow clone)
- **Aqua-Sim-NG 仓库**:`https://github.com/rmartin5/aqua-sim-ng.git`(UWSN Lab 维护)
- **构建目标**:**2015/2015 全过**,0 error(第一轮 `-Werror=parentheses` 挂 2 处,
  patch + `CXXFLAGS=-Wno-error` 修复)
- **demo 验证**:

```
./ns3 run hello-simulator          → "Hello Simulator"  ✅
./ns3 run JmacTest                 → Sent=4, SendUp=2, Phy=14  ✅
./ns3 run broadcastMAC_example     → fin  ✅
./ns3 run VBF                      → Sent=40, SendUp=40, Phy=47210  ✅
python3 tests/smoke/test_aqua_sim_aloha.py  → stub JSON exit 0  ✅
```

---

## 核心方法论发现

### ✅ 得到验证的

1. **GAN harness 有效**:Planner 自评虚报从 v1 的 **+10** 降到 v2 的 **+3**,
   两轮校准 70%
2. **Δ+9 > `convergence_delta_min: 5`**:收敛判据可用,无假阳性
3. **"Evaluator 是敌人"有效**:独立 grep 抓到 5 个裸 wikilink + 16 处散文化 EC +
   1 条循环引用
4. **红线机制有效**:Planner 自检时发现 R-X1 违反 `never_touch`,就地修正为
   桥接脚本方案(后又在 2026-04-27 Q1 决策时进一步收紧为"PR 路径,不做合成")
5. **调试期隔离有效**:worktree 独立,未触碰主 UWAnet 仓

### ❌ 被实测纠偏的

1. **"只修不写"的 v2 迭代实际成本与 v1 相当**(文件行数 576 → 872,
   token 124k > v1 97k)。**原因**:rubric 升级会触发全量扫查
2. **Phase 4 Evaluator 的机器硬验证依赖 Bash 权限**,subagent 默认被拒 →
   82 FAIL 非产物问题。需 `settings.local.json` 白名单
3. **Phase 3/4 看不出 upstream 代码兼容问题**(`-Werror=parentheses`),
   只有真装机才暴露 → Phase 4 rubric 应加"最小装机验证"

---

## 发现的 3 个新 Pitfall(已补到 Hub exploration 页)

### #7 Subagent Bash 运行时隐式拦截

**修复**:`.claude/settings.local.json` 显式 allow Bash matcher。

### #8 Upstream 代码 vs 新 GCC 不兼容

**现象**:Aqua-Sim-NG `master` 在新版 GCC 下触发 `-Werror=parentheses` 2 处。

**修复**:patch 源码(2 处加括号消歧)+ `CXXFLAGS=-Wno-error` 兜底。
本仓 `workflows/01-env-setup.md` §2.2 已加[!warning]块。

### #9 ns-3.41 API 变更(Planner 训练数据过时)

**现象**:Planner 输出的 example target 名(如 `aqua-sim-mac-aloha`)在
ns-3.41 实际是 `JmacTest`(CamelCase)。

**修复**:`goal.yaml` 版本锁定 ns-3.41 + 用 `./ns3 show examples` 列实际 target;
本仓 `workflows/01-env-setup.md` §4.2 已加[!note]块。

---

## 可复用资产(主仓视角)

| 资产 | 主仓位置 | 适用范围 |
|---|---|---|
| install 脚本 | `src/setup/install_ns3_aquasim.sh` | M1 装机入口 |
| smoke test | `tests/smoke/test_aqua_sim_aloha.py` | M1 Exit Criteria |
| M0 章程 | `specs/active/M0-charter.md` | M0 收口 |
| 路线图 | `plans/roadmap.md` | M1-M5 全程 |
| 架构 | `plans/architecture.md` | 协议栈 + UWAcomm 接口 |
| 风险 | `plans/risks.md` | M1-M5 全程 |
| 环境 workflow | `workflows/01-env-setup.md` | M1 操作手册 |

---

## 下一步路径(主仓视角)

- **立即可做**:在 WSL 侧重新跑一次 `install_ns3_aquasim.sh` 验证主仓副本无回归
  (dry-run 装机已在 `/home/lyren/ns3-workspace/` 留有 cache,新仓只需复用)
- **M1 收口**:`workflows/01-env-setup.md` §M1 Exit Criteria 5 项打勾
- **M2 启动**:阅读 `src/aqua-sim-ng/model/aqua-sim-mac-aloha.cc`,产出
  `wiki/explorations/aqua-sim-mac-aloha-walkthrough.md`
- **R-X1 PR**:在 UWAcomm 项目侧(独立 session)开 PR,加 `export_phy_trace.m`
  逐帧 dump 能力(Q1 决策)。M3 不阻塞,M4 启动前需 PR 合并。

---

## 参考

- Hub 方法论:`D:/Claude/Ohmybrain/wiki/explorations/autonomous-new-project-workflow.md`
- Hub log:`D:/Claude/Ohmybrain/wiki/log.md` §[2026-04-21] phase4-5 dry-run
- UWAnet 项目导航:`D:/Claude/Ohmybrain/projects/uwanet/README.md`
- worktree 原 dry-run 报告:`D:/Claude/worktrees/uwanet-redo/run-report.md`
- worktree 原 scaffold 报告:`D:/Claude/worktrees/uwanet-redo/scaffold-report.md`

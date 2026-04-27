---
type: workflow
created: 2026-04-21
updated: 2026-04-27
tags: [M1, 环境搭建, ns-3, Aqua-Sim-NG, WSL2, Ubuntu]
milestone: M1
---

# 01 — M1 环境搭建操作手册

> **里程碑**：M1 Environment & Boot
> **目标**：在 WSL2 Ubuntu 22.04 内搭好 ns-3.41 + Aqua-Sim-NG 编译环境，跑通 hello-simulator 与 aqua-sim-mac-aloha 验证示例。
> **来源**：2026-04-21 dry-run worktree 已实测 2015/2015 编过；本文档为同步回主仓的复刻指南。
> **权威参考**：
> - `[[wiki/source-summaries/ns3-installation-guide.md]]` — WSL2 装机完整流程（CSDN + 官方）
> - `[[wiki/source-summaries/aqua-sim-family.md]]` — Aqua-Sim 版本依赖与家族演进
> - `[[wiki/explorations/uwanet-dryrun-2026-04-21]]` — dry-run 复盘（含 GCC patch / API 变更等踩坑）

---

## 前置条件

在开始前，请确认以下条件全部满足：

| 条件 | 检查方法 | 说明 |
|------|---------|------|
| Windows 11 + Hyper-V 启用 | `bcdedit /enum` 查看 `hypervisorlaunchtype auto` | WSL2 依赖 Hyper-V |
| WSL2 已安装 | `wsl --version` | 版本 ≥ 2.0 |
| Ubuntu 22.04 子系统已安装 | `wsl -l -v` 列出 Ubuntu | 也可用 Ubuntu 20.04 |
| 磁盘空间 ≥ 15 GB | 在 WSL 内 `df -h ~` | ns-3 源码 + 编译产物约 10 GB |
| 网络可访问 GitLab / GitHub | `curl https://gitlab.com` | 或配置 Git 代理 |

---

## 步骤 1：WSL2 + Ubuntu 22.04 安装与迁移

### 1.1 安装 WSL2

以管理员身份打开 PowerShell，执行：

```powershell
# 启用 WSL2
wsl --install
# 或者指定发行版
wsl --install -d Ubuntu-22.04
```

如果已有 WSL1，升级到 WSL2：

```powershell
wsl --set-version Ubuntu-22.04 2
wsl --set-default-version 2
```

### 1.2 迁移到非系统盘（推荐迁移到 D 盘）

```powershell
# 打包当前 Ubuntu（管理员 PowerShell）
wsl --export Ubuntu-22.04 D:\ubuntu2204-backup.tar

# 注销 C 盘版本
wsl --unregister Ubuntu-22.04

# 重新导入到 D 盘
wsl --import Ubuntu-22.04 D:\Ubuntu_22_04\ D:\ubuntu2204-backup.tar --version 2

# 恢复默认用户（替换 <your-username>）
# 在 Ubuntu 中执行：sudo usermod -aG sudo <your-username>
wsl --setdefault Ubuntu-22.04
```

> **关键原则**：ns-3 源码必须存放在 WSL 文件系统内（如 `/home/<user>/`），**不得**放在 `/mnt/c` 或 `/mnt/d`。
> 跨文件系统 I/O 会使编译速度降低 10-20 倍。
> 详见 `[[wiki/source-summaries/ns3-installation-guide.md]]` §核心设计原则。

### 1.3 验证 WSL2 正常工作

```bash
# 在 WSL Ubuntu 内确认
uname -r          # 应输出带 "microsoft" 字样的内核版本
echo $HOME        # 应输出 /home/<user>（不是 /mnt/...）
df -h ~           # 确认有足够磁盘空间
```

---

## 步骤 2：运行 install_ns3_aquasim.sh

### 2.1 复制脚本到 WSL

主仓内脚本位置：

```
D:\Claude\TechReq\UWAnet\src\setup\install_ns3_aquasim.sh
```

在 WSL Ubuntu 内访问同一路径（Windows D 盘在 WSL 内挂载为 `/mnt/d`）：

```bash
cp /mnt/d/Claude/TechReq/UWAnet/src/setup/install_ns3_aquasim.sh ~/install_ns3_aquasim.sh
chmod +x ~/install_ns3_aquasim.sh
```

### 2.2 执行安装脚本

```bash
# 在 WSL Ubuntu 内，HOME 目录下执行
cd ~
bash install_ns3_aquasim.sh 2>&1 | tee install-log.txt
```

脚本会依次完成：

1. 环境预检（确认不在 `/mnt/...`）
2. `sudo apt-get install` 安装系统依赖（g++、cmake、ninja-build、git 等）
3. `git clone --branch ns-3.41 --depth 1` 下载 ns-3-dev 源码（约 300 MB）
4. `git clone` Aqua-Sim-NG 到 `ns-3-dev/src/aqua-sim-ng/`
5. `./ns3 configure` 配置构建系统（cmake + ninja 后端）
6. `./ns3 build` 编译（首次约 20-40 分钟）
7. 运行 `hello-simulator` 和 `aqua-sim-mac-aloha` 验证

> [!warning] 已知 GCC 兼容坑（dry-run 实测）
> Aqua-Sim-NG 在新版 GCC 下会触发 `-Werror=parentheses` 2 处编译错误。脚本默认
> 不带 `CXXFLAGS=-Wno-error`，首轮挂掉后请：
> ```bash
> export CXXFLAGS=-Wno-error
> ./ns3 clean && ./ns3 configure --enable-examples --enable-tests --build-profile=debug
> ./ns3 build
> ```
> 详见 [[wiki/explorations/uwanet-dryrun-2026-04-21]] §pitfall #8。

### 2.3 国内镜像加速（可选）

如果 `apt-get` 速度慢，先切换 apt 源：

```bash
# 备份原始源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 替换为 USTC 镜像（Ubuntu 22.04 Jammy）
sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list
sudo sed -i 's|http://security.ubuntu.com|https://mirrors.ustc.edu.cn|g' /etc/apt/sources.list

# 或 BFSU（北外）镜像
# sudo sed -i 's|http://archive.ubuntu.com|https://mirrors.bfsu.edu.cn|g' /etc/apt/sources.list
```

如果 `git clone gitlab.com` 慢，配置 Git HTTP 代理：

```bash
# 若已有本地代理（如 Clash，端口 7890）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890
```

---

## 步骤 3：VSCode + WSL Remote 联调配置

### 3.1 安装 VSCode 扩展

在 Windows 上的 VSCode 中安装：

- `Remote - WSL`（微软官方）：在 WSL 内打开文件夹
- `C/C++`（微软）：C++ 语法高亮、IntelliSense
- `CMake Tools`：CMake 项目支持

### 3.2 打开 WSL 工作区

```bash
# 在 WSL Ubuntu 内执行（首次会自动安装 VS Code Server）
cd ~/ns3-workspace/ns-3-dev
code .
```

VSCode 左下角应显示 `WSL: Ubuntu-22.04`，确认连接到 WSL。

### 3.3 配置 IntelliSense（C++ 头文件路径）

在 VSCode 中按 `Ctrl+Shift+P`，选择 `C/C++: Edit Configurations (JSON)`，添加：

```json
{
  "configurations": [
    {
      "name": "WSL-ns3",
      "includePath": [
        "${workspaceFolder}/**",
        "${workspaceFolder}/build/include/**"
      ],
      "defines": [],
      "compilerPath": "/usr/bin/g++",
      "cStandard": "c17",
      "cppStandard": "c++17",
      "intelliSenseMode": "linux-gcc-x64"
    }
  ]
}
```

> 详见 `[[wiki/source-summaries/ns3-installation-guide.md]]` §配置调试（ns-3.37+）

---

## 步骤 4：验证安装（hello-simulator + aqua-sim-mac-aloha）

### 4.1 验证 ns-3 基础功能

```bash
cd ~/ns3-workspace/ns-3-dev

# 测试 1：ns-3 核心示例
./ns3 run hello-simulator
# 预期输出：Hello Simulator

# 测试 2：列出可用 Aqua-Sim 示例
./ns3 show examples | grep -i aqua
```

### 4.2 验证 Aqua-Sim-NG MAC 示例

```bash
# 运行 ALOHA MAC 示例（具体名称视 Aqua-Sim-NG 版本）
./ns3 run "aqua-sim-mac-aloha"

# dry-run 实测以下 4 个 example 全过：
./ns3 run JmacTest                  # → Sent=4, SendUp=2, Phy=14
./ns3 run broadcastMAC_example      # → fin
./ns3 run VBF                       # → Sent=40, SendUp=40, Phy=47210

# 若示例名称不同（ns-3.41 用 CamelCase target 名，与旧文档不一致）：
./ns3 show examples | grep -i aloha
```

> [!note] ns-3.41 API 变更（dry-run 实测）
> ns-3.41 的 example target 名采用 CamelCase（如 `JmacTest` 而非 `jmac-test`），
> Planner 训练数据可能落后 → 用 `./ns3 show examples` 查询当前版本可用名。
> 详见 [[wiki/explorations/uwanet-dryrun-2026-04-21]] §pitfall #9。

### 4.3 运行 Python Smoke Test（stub 模式）

从主仓根目录（Windows 侧）：

```bash
# 在 Windows PowerShell / cmd
python D:\Claude\TechReq\UWAnet\tests\smoke\test_aqua_sim_aloha.py
```

或在 WSL 内（stub 模式无需 ns-3）：

```bash
python3 /mnt/d/Claude/TechReq/UWAnet/tests/smoke/test_aqua_sim_aloha.py
```

预期输出（exit code = 0，stub 模式，num_nodes=10）：

```json
{
  "packets_sent": 1000,
  "packets_received": 16,
  "throughput": 1300.0,
  "collision_rate": 0.984,
  "channel_utilization": 0.13,
  "simulation_time_s": 100.0,
  "num_nodes": 10,
  "mac_protocol": "ALOHA",
  "stub_mode": true
}
```

`throughput` 单位为 **bps**（与 plot_results.py / results.csv `throughput_bps` 字段对齐）。

---

## M1 Exit Criteria 核查清单

按照 `plans/roadmap.md` §M1 的验收标准逐条检查：

- [ ] `bash -n src/setup/install_ns3_aquasim.sh` 退出码 0（语法检查）
- [ ] 脚本内含 `apt-get` / `git clone` / `cmake` / `make` 关键字
- [ ] `./ns3 run hello-simulator` 退出码 0，stdout 含 `Hello Simulator`
- [ ] `./ns3 run JmacTest` 或 `./ns3 run broadcastMAC_example` 退出码 0
- [ ] `tests/smoke/test_aqua_sim_aloha.py` 退出码 0，输出含 `packets_sent` 和 `throughput`（bps）
- [ ] 本文档 ≥ 30 行，引用两份 source-summary

---

## 常见坑位

| 现象 | 根因 | 解法 |
|------|------|------|
| 编译极慢（数小时） | ns-3 源码在 `/mnt/d/...` 而非 WSL 内 | `cp -r /mnt/d/.../ns-3-dev ~/`，在 Linux 文件系统内编译 |
| `./waf: 未找到命令` | ns-3 ≥ 3.36 已废弃 `waf`，改用 `./ns3` | 用 `./ns3 configure` 和 `./ns3 build` |
| `-Werror=parentheses` 编译挂 | Aqua-Sim-NG 与新 GCC 不兼容（dry-run pitfall #8） | `export CXXFLAGS=-Wno-error` 后 `./ns3 clean && ./ns3 configure && ./ns3 build` |
| Example 找不到（`jmac-test` 等小写名） | ns-3.41 改 CamelCase target 名（pitfall #9） | `./ns3 show examples` 查当前可用名 |
| VSCode 语言提示是 Windows 侧 | WSL Remote 扩展未启用 | 重新 `code .`，确认左下角显示 `WSL:` |
| `hello-simulator` 段错误 | 缺少 `libsqlite3-dev` 等依赖 | `sudo apt-get install libsqlite3-dev libxml2-dev` |
| Aqua-Sim 示例找不到 | 模块未注册到 cmake | 检查 `src/aqua-sim-ng/CMakeLists.txt` 是否正确 |
| `git clone` SSH 失败 | GitLab SSH Key 未配置 | 改用 HTTPS：`git clone https://gitlab.com/...` |
| Hyper-V 冲突 | VMware/VirtualBox 与 Hyper-V 互斥 | `bcdedit /set hypervisorlaunchtype auto` 后重启 |
| WSL2 内存不足 | 默认内存限制过低 | 在 `%USERPROFILE%\.wslconfig` 内增加 `memory=8GB` |

> 更多坑位参见 `[[wiki/source-summaries/ns3-installation-guide.md]]` §常见坑位
> Aqua-Sim 版本兼容性见 `[[wiki/source-summaries/aqua-sim-family.md]]` §版本依赖
> dry-run 实测踩坑详见 `[[wiki/explorations/uwanet-dryrun-2026-04-21]]`

---

## 相关文件

- `src/setup/install_ns3_aquasim.sh` — 本文档对应的自动化安装脚本
- `tests/smoke/test_aqua_sim_aloha.py` — M1 Smoke Test（STUB 模式）
- `plans/roadmap.md` §M1 — 里程碑 Exit Criteria 完整定义
- `wiki/source-summaries/ns3-installation-guide.md` — WSL2 + ns-3 装机权威参考
- `wiki/source-summaries/aqua-sim-family.md` — Aqua-Sim 版本演进与选型依据
- `wiki/explorations/uwanet-dryrun-2026-04-21.md` — dry-run 复盘（pitfall #7-#9）

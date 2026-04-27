---
type: source-summary
source_type: course
created: 2026-04-21
updated: 2026-04-21
tags: [ns-3, WSL2, 环境搭建, VSCode, Ubuntu]
---

# NS-3 环境搭建指南（Windows → WSL2 → Ubuntu → ns-3）

> **原始资料**：
> - `raw/courses/NS3资料/NS3安装教程/基于 WSL2 的 NS3 环境搭建教程_wsl 支持 ns3 吗 - CSDN 博客.pdf`
> - `raw/courses/NS3资料/NS3安装教程/在 Win11 安装 Ubuntu20_04 子系统 WSL2 到其他盘... - CSDN 博客.pdf`
> - `raw/courses/NS3资料/NS3安装教程/【ns-3】VS Code 开发环境配置_如何用 vscode 打开 ns3-CSDN 博客.pdf`
> - `raw/courses/NS3资料/NS3官方文档/ns-3-installation.pdf`（ns-3.39 官方）

## 推荐路线（综合三篇 CSDN + 官方）

```
Windows 11
   ├─ WSL2 (Ubuntu 20.04, 安装到 D 盘)
   │    └─ ns-3 源码（编译，位于 WSL 文件系统内）
   └─ VS Code (Windows 原生)
         └─ WSL Remote 扩展 → 对接 WSL 里的 ns-3
```

**核心设计原则**：ns-3 必须在 WSL 文件系统内编译（`/home/...`），**不得**放到 `/mnt/c` 或 `/mnt/d`，否则 WSL2 跨 OS 文件系统性能极差，编译异常缓慢。

## 关键步骤（精简版）

### 1. WSL2 + Ubuntu 20.04 迁移到 D 盘

```powershell
# 管理员 PowerShell
wsl --set-default-version 1               # 先装到 C 盘以 wsl1 方式
# Microsoft Store 安装 Ubuntu 20.04（先到 C 盘）
# 启动 Ubuntu 设置用户名/密码 + 设置 su 密码：sudo passwd

wsl --export Ubuntu20.04 D:\export.tar    # 打包
wsl --unregister Ubuntu-20.04             # 注销 C 盘版本
wsl --set-default-version 2               # 升级到 WSL2
wsl --import Ubuntu-20.04 D:\Ubuntu_20_04\ D:\export.tar --version 2
wsl --setdefault Ubuntu-20.04
Ubuntu2004 config --default-user <你的用户名>   # 恢复非 root 用户
```

若 `wsl --import` 失败，用 `bcdedit /set hypervisorlaunchtype auto` 恢复 Hyper-V 后重试。

### 2. 下载编译 ns-3（在 WSL Ubuntu 内）

```bash
# 在 /home/<user>/ 下，不要在 /mnt/...
ssh-keygen -t rsa   # 生成 key，粘贴到 gitlab 账户
git clone git@gitlab.com:nsnam/ns-3-dev.git

cd ns-3-dev
# 旧版（< 3.36）: ./waf configure --build-profile=debug --enable-examples --enable-tests
# 新版（≥ 3.36）: ./ns3 configure --enable-examples --enable-tests
./ns3 configure --enable-examples --enable-tests
./ns3 build
./ns3 run hello-simulator   # 验证
```

### 3. VS Code + WSL Remote

- Windows 装 VS Code；扩展搜 `Remote - WSL` 并安装
- 在 WSL Ubuntu 内执行 `code .`（第一次会自动在 WSL 内装 VS Code Server）
- 在 **WSL 上**（不是 Windows 上）装：`C/C++` 插件 + `CMake` 插件
- VS Code 左下角应显示 `WSL: Ubuntu-20.04`

### 4. 配置调试（ns-3.37+）

- `Ctrl+Shift+P` → `C/C++: Edit Configurations (JSON)` → 配 `includePath`
- `tasks.json` 默认 `./ns3` build 命令，一般无需改
- `launch.json` 把 `"program"` 从 `"ns3-dev"` 改为具体版本号（如 `"ns3.37"`）

## 官方系统要求（ns-3.39）

| 平台 | 建议版本 |
|------|---------|
| **Linux**（强推）| Ubuntu 20.04+ / Debian 11+ / Fedora |
| macOS | 11+（需 Homebrew + Xcode） |
| Windows | **仅 WSL2**（原生 Win 支持已放弃） |

**必装依赖**（Ubuntu）：
```bash
sudo apt install g++ python3 cmake ninja-build git ccache
# 可选：gcc-10/11，python3-dev，doxygen，gsl，sqlite3
```

## 常见坑位

| 现象 | 根因 | 解法 |
|------|------|------|
| 编译极慢 | ns-3 装在 `/mnt/d` | 迁移到 WSL 内 `/home/<user>/` |
| `./waf` 找不到 | ns-3 ≥ 3.36 已废弃 waf | 用 `./ns3` |
| VS Code 提示仍是 Windows | WSL Remote 未启用 | 左下角确认 `WSL:...` |
| `hello-simulator` 报错 | 依赖缺失 | 按 `ns-3-installation.pdf` 第 4 章补 |

## UWAnet 项目使用价值

> 直接用于 **[[uwanet-moc-v1|M1 环境搭建]]**，将成为 `src/setup/install_ns3_aquasim.sh` 的蓝本。Aqua-Sim-NG 基于 ns-3，所以 ns-3 必须先跑通。

## 相关页面

- [[uwanet-brainstorm]] — 平台选型，本指南是其"环境搭建"章节的原始依据
- [[ns3-documentation-index]] — 进阶：ns-3 官方 manual / tutorial / model-library
- [[dashboard]]

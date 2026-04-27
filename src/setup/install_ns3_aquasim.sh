#!/usr/bin/env bash
# ==============================================================================
# install_ns3_aquasim.sh — UWAnet M1 环境搭建脚本
#
# 目标环境：WSL2 Ubuntu 22.04（或 Ubuntu 20.04）
# 用法：在 WSL Ubuntu 终端内手动执行：bash install_ns3_aquasim.sh
#
# 版本：1.0  日期：2026-04-21
# 对齐：goal.yaml.rubric.m1_environment.setup_script
# ==============================================================================

echo "[WARN] 此脚本在目标机器上手动执行，不在 worktree 内跑"
echo "[INFO] 目标：WSL2 Ubuntu 22.04，安装 ns-3-dev + Aqua-Sim-NG"
echo "[INFO] 预计耗时：首次编译约 20-40 分钟（视机器性能）"
echo ""

set -euo pipefail

# ------------------------------------------------------------------------------
# 工具函数
# ------------------------------------------------------------------------------
log_step() {
    echo ""
    echo "========================================"
    echo "[STEP] $1"
    echo "========================================"
}

check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "[ERROR] 未找到命令: $cmd"
        return 1
    fi
    echo "[OK] $cmd 已就绪"
}

# ------------------------------------------------------------------------------
# 关键常量
# ------------------------------------------------------------------------------
NS3_REPO="https://gitlab.com/nsnam/ns-3-dev.git"
# 也可以用 SSH 方式（需提前配 gitlab ssh key）：
# NS3_REPO="git@gitlab.com:nsnam/ns-3-dev.git"

AQUASIM_REPO="https://github.com/rmartin5/aqua-sim-ng.git"
INSTALL_DIR="${HOME}/ns3-workspace"
NS3_DIR="${INSTALL_DIR}/ns-3-dev"
AQUASIM_DIR="${NS3_DIR}/src/aqua-sim-ng"

# ------------------------------------------------------------------------------
# 预检：确认在 WSL2 Linux 文件系统内（不在 /mnt/...）
# ------------------------------------------------------------------------------
log_step "0. 环境预检"

if [[ "${HOME}" == /mnt/* ]]; then
    echo "[ERROR] 检测到 HOME 位于 /mnt/... (Windows 盘)，性能极差！"
    echo "[ERROR] 请在 WSL2 Linux 文件系统内操作，例如 /home/<user>/"
    echo "[HINT]  在 WSL 中执行：cd ~ && pwd  应输出 /home/<user>"
    exit 1
fi

echo "[OK] HOME=${HOME}，位于 WSL 文件系统内"

# 检查架构
ARCH=$(uname -m)
OS_ID=$(. /etc/os-release && echo "$ID")
OS_VER=$(. /etc/os-release && echo "$VERSION_ID")
echo "[INFO] 系统：${OS_ID} ${OS_VER} (${ARCH})"

if [[ "$OS_ID" != "ubuntu" ]]; then
    echo "[WARN] 当前非 Ubuntu，依赖安装命令可能需要调整"
fi

# ------------------------------------------------------------------------------
# 步骤 1：更新软件源 + 安装系统依赖
# ------------------------------------------------------------------------------
log_step "1. 安装系统依赖（apt-get）"

echo "[INFO] 更新 apt 软件源..."
sudo apt-get update -y

echo "[INFO] 安装 ns-3 必要依赖..."
sudo apt-get install -y \
    g++ \
    python3 \
    python3-dev \
    python3-pip \
    cmake \
    ninja-build \
    git \
    ccache \
    pkg-config \
    libsqlite3-dev \
    libxml2-dev \
    libgsl-dev \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    gdb \
    valgrind

echo "[INFO] 安装可选增强依赖..."
sudo apt-get install -y \
    libboost-all-dev \
    libopenmpi-dev \
    libgraphviz-dev \
    python3-gi \
    python3-gi-cairo \
    python3-pygraphviz || echo "[WARN] 部分可选依赖安装失败（不影响核心功能）"

echo "[OK] 系统依赖安装完成"

# 验证关键工具
check_command g++
check_command cmake
check_command git
check_command python3

# 显示版本信息
echo "[INFO] g++ 版本: $(g++ --version | head -1)"
echo "[INFO] cmake 版本: $(cmake --version | head -1)"
echo "[INFO] python3 版本: $(python3 --version)"

# ------------------------------------------------------------------------------
# 步骤 2：创建工作目录，下载 ns-3 源码
# ------------------------------------------------------------------------------
log_step "2. 下载 ns-3-dev 源码（git clone）"

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

if [[ -d "${NS3_DIR}" ]]; then
    echo "[INFO] 目录 ${NS3_DIR} 已存在，跳过克隆（如需重新下载请手动 rm -rf）"
else
    echo "[INFO] git clone ${NS3_REPO} (branch: ns-3.41, shallow) ..."
    echo "[NOTE] 若网络较慢，可考虑使用 HTTPS 镜像或配置 Git 代理"
    # 锁定 ns-3.41 tag 以匹配 Aqua-Sim-NG README 推荐版本；shallow clone 节省时间/空间
    git clone --branch ns-3.41 --depth 1 "${NS3_REPO}" ns-3-dev
    echo "[OK] ns-3-dev 克隆完成（ns-3.41，shallow clone）"
fi

cd "${NS3_DIR}"
echo "[INFO] 当前 ns-3 分支: $(git rev-parse --abbrev-ref HEAD)"
echo "[INFO] 最新 commit: $(git log --oneline -1)"

# ------------------------------------------------------------------------------
# 步骤 3：集成 Aqua-Sim-NG（git clone 到 src/ 下）
# ------------------------------------------------------------------------------
log_step "3. 集成 Aqua-Sim-NG（git clone 到 src/aqua-sim-ng）"

if [[ -d "${AQUASIM_DIR}" ]]; then
    echo "[INFO] Aqua-Sim-NG 目录已存在，跳过克隆"
else
    echo "[INFO] git clone ${AQUASIM_REPO} ..."
    git clone "${AQUASIM_REPO}" src/aqua-sim-ng
    echo "[OK] Aqua-Sim-NG 克隆完成"
fi

echo "[INFO] Aqua-Sim-NG 位置: ${AQUASIM_DIR}"
ls -la "${AQUASIM_DIR}/" | head -20

# ------------------------------------------------------------------------------
# 步骤 4：CMake 配置 + 构建（make / ninja）
# ------------------------------------------------------------------------------
log_step "4. 配置 ns-3（cmake + ninja）并构建（make 兼容）"

cd "${NS3_DIR}"

echo "[INFO] 运行 ./ns3 configure ..."
echo "[NOTE] --enable-examples：编译官方示例；--enable-tests：编译测试套件"
./ns3 configure \
    --enable-examples \
    --enable-tests \
    --build-profile=debug

echo ""
echo "[INFO] 开始构建（./ns3 build）... 这一步耗时最长，请耐心等待"
echo "[NOTE] 等价于在 cmake_cache/ 下执行 cmake --build . 或 make -j$(nproc)"
./ns3 build

echo "[OK] ns-3 + Aqua-Sim-NG 构建完成"

# 也可以直接用 cmake + make 方式（等价，供参考）：
# mkdir -p cmake_cache && cd cmake_cache
# cmake .. -G Ninja -DNS3_ENABLED_MODULES="aqua-sim-ng;core;network;mobility;..."
# make -j$(nproc)

# ------------------------------------------------------------------------------
# 步骤 5：验证安装
# ------------------------------------------------------------------------------
log_step "5. 验证安装"

cd "${NS3_DIR}"

echo "[TEST 1] 运行 hello-simulator..."
./ns3 run hello-simulator
echo "[OK] hello-simulator 通过"

echo ""
echo "[TEST 2] 运行 aqua-sim-mac-aloha（Aqua-Sim-NG 基础 MAC 示例）..."
# 注意：具体 example 名称可能因 Aqua-Sim-NG 版本而异
# 可先用 ./ns3 show examples | grep aqua 查看可用示例
if ./ns3 run "aqua-sim-mac-aloha" 2>&1 | grep -q "packets_sent\|Packets sent\|simulation"; then
    echo "[OK] aqua-sim-mac-aloha 通过"
else
    echo "[WARN] aqua-sim-mac-aloha 未找到明确输出，请检查 Aqua-Sim-NG 示例名称"
    echo "[HINT] 用以下命令查看可用示例："
    echo "       ./ns3 show examples | grep -i aqua"
fi

# ------------------------------------------------------------------------------
# 总结
# ------------------------------------------------------------------------------
echo ""
echo "========================================"
echo "[DONE] UWAnet M1 环境搭建完成！"
echo "========================================"
echo ""
echo "安装位置：${NS3_DIR}"
echo "Aqua-Sim-NG：${AQUASIM_DIR}"
echo ""
echo "后续步骤："
echo "  1. VSCode WSL Remote 配置（见 workflows/01-env-setup.md §步骤3）"
echo "  2. 运行 smoke test：python tests/smoke/test_aqua_sim_aloha.py"
echo "  3. 进入 M2：阅读 src/aqua-sim-ng/model/aqua-sim-mac-aloha.cc"
echo ""
echo "遇到问题请参考："
echo "  - wiki/source-summaries/ns3-installation-guide.md（常见坑位）"
echo "  - wiki/source-summaries/aqua-sim-family.md（版本依赖说明）"

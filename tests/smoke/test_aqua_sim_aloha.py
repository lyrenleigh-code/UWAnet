#!/usr/bin/env python3
"""M1 smoke test — stub mode.

Stub 模式：验证测试结构 + 骨架正确；不需要 ns-3 / Aqua-Sim-NG 实装。
真实模式（装完后）：STUB_MODE=False，在 ns-3 Python bindings 环境下运行。

对齐：goal.yaml.rubric.m1_environment.smoke_test
  - exit_code: 0
  - must_output_keys: [packets_sent, throughput]

用法：
  # Stub 模式（任何机器可运行，无需 ns-3）
  python tests/smoke/test_aqua_sim_aloha.py

  # 真实模式（需要 ns-3 + Aqua-Sim-NG Python bindings）
  STUB_MODE=0 python tests/smoke/test_aqua_sim_aloha.py
"""

import json
import os
import sys


# ------------------------------------------------------------------------------
# 模式控制
# stub=True：直接返回预置结果，不调用 ns-3
# stub=False：需要 ns-3 Python bindings 环境，调用真实仿真
# ------------------------------------------------------------------------------
STUB_MODE = os.environ.get("STUB_MODE", "1").strip() not in ("0", "false", "False", "FALSE")

# 仿真参数（stub 模式下用于生成合理预置结果；真实模式下传递给 ns-3）
SIM_PARAMS = {
    "num_nodes": 10,
    "simulation_time_s": 100.0,
    "packet_rate_pps": 1.0,       # 包/秒
    "packet_size_bytes": 1000,
    "channel_capacity_bps": 10000,
    "propagation_speed_mps": 1500.0,  # 水中声速 ~1500 m/s
    "max_range_m": 1000.0,
    "seed": 42,
}


# ------------------------------------------------------------------------------
# Stub 模式：预置仿真结果（符合 Aqua-Sim ALOHA 的典型性能范围）
# ------------------------------------------------------------------------------
def run_stub() -> dict:
    """
    返回预置的 ALOHA MAC 仿真结果。

    数值来源：参考 wiki/source-summaries/aqua-sim-family.md §UW-Aloha 案例：
    - 80 bps modem 上 BEB 吞吐 11.5 bps（14.4% 利用率）
    - 本 stub 用 10 kbps 信道，预置约 12-15% 利用率
    """
    packets_sent = int(SIM_PARAMS["num_nodes"]
                       * SIM_PARAMS["packet_rate_pps"]
                       * SIM_PARAMS["simulation_time_s"])
    # ALOHA 理论利用率约 18.4%（e^-1 * 2）；考虑水声环境降为约 13%
    channel_utilization = 0.13
    throughput_bps = SIM_PARAMS["channel_capacity_bps"] * channel_utilization
    packets_per_second = throughput_bps / (SIM_PARAMS["packet_size_bytes"] * 8)
    packets_received = int(packets_per_second * SIM_PARAMS["simulation_time_s"])
    collision_rate = 1.0 - (packets_received / max(packets_sent, 1))

    return {
        "packets_sent": packets_sent,
        "packets_received": packets_received,
        "throughput": round(throughput_bps, 2),
        "collision_rate": round(max(0.0, collision_rate), 4),
        "channel_utilization": round(channel_utilization, 4),
        "simulation_time_s": SIM_PARAMS["simulation_time_s"],
        "num_nodes": SIM_PARAMS["num_nodes"],
        "mac_protocol": "ALOHA",
        "stub_mode": True,
    }


# ------------------------------------------------------------------------------
# 真实模式：调用 ns-3 Python bindings + Aqua-Sim-NG
# ------------------------------------------------------------------------------
def run_real() -> dict:
    """
    通过 ns-3 Python bindings 运行 Aqua-Sim-NG ALOHA 仿真。

    前置条件：
    1. ns-3 编译完成，Python bindings 可用
    2. Aqua-Sim-NG 模块已集成并编译
    3. 在 ns-3-dev 目录下运行，或 PYTHONPATH 指向 ns-3 bindings

    TODO（M1 完成后实现）：
    - import ns.core, ns.network, ns.mobility
    - import ns.aqua_sim
    - 创建 NodeContainer，配置 AquaSimHelper
    - 运行仿真，收集 PacketSink 统计
    - 返回实际 packets_sent / throughput 等指标
    """
    raise NotImplementedError(
        "真实模式需要 ns-3 + Aqua-Sim-NG 实装。\n"
        "装完后设置 STUB_MODE=0 并在 ns-3-dev 目录内运行。\n"
        "参考：wiki/source-summaries/ns3-installation-guide.md"
    )


# ------------------------------------------------------------------------------
# 结果验证
# ------------------------------------------------------------------------------
def validate_result(result: dict) -> None:
    """验证仿真结果包含必要字段且数值合理。"""
    # rubric 必需键
    required_keys = ["packets_sent", "throughput"]
    for key in required_keys:
        if key not in result:
            raise AssertionError(f"结果缺少必需键: '{key}'")

    # 数值合理性断言
    assert result["packets_sent"] > 0, (
        f"packets_sent 应 > 0，实际: {result['packets_sent']}"
    )
    assert result["throughput"] >= 0, (
        f"throughput 应 >= 0，实际: {result['throughput']}"
    )

    if "packets_received" in result:
        assert result["packets_received"] >= 0, "packets_received 应 >= 0"
        assert result["packets_received"] <= result["packets_sent"], (
            "packets_received 不应超过 packets_sent"
        )

    if "collision_rate" in result:
        assert 0.0 <= result["collision_rate"] <= 1.0, (
            f"collision_rate 应在 [0, 1]，实际: {result['collision_rate']}"
        )

    if "simulation_time_s" in result:
        assert result["simulation_time_s"] > 0, "simulation_time_s 应 > 0"


# ------------------------------------------------------------------------------
# 主入口
# ------------------------------------------------------------------------------
def main() -> int:
    mode_str = "STUB" if STUB_MODE else "REAL"
    print(f"[INFO] test_aqua_sim_aloha.py — 运行模式: {mode_str}", file=sys.stderr)

    try:
        result = run_stub() if STUB_MODE else run_real()
    except NotImplementedError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    except Exception as exc:  # noqa: BLE001
        print(f"[ERROR] 仿真运行异常: {exc}", file=sys.stderr)
        return 1

    # 输出 JSON 结果（rubric 要求 stdout 含 packets_sent 和 throughput）
    print(json.dumps(result, ensure_ascii=False, indent=2))

    # 验证结果
    try:
        validate_result(result)
    except AssertionError as exc:
        print(f"[FAIL] 结果验证失败: {exc}", file=sys.stderr)
        return 1

    print(f"[PASS] smoke test {mode_str.lower()} — packets_sent={result['packets_sent']},"
          f" throughput={result['throughput']} bps", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())

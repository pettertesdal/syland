# syland-sysstats: backend for windows/StatsModule.qml (mirrors
# windows/MusicModule.qml at the bottom of the screen) via
# services/SysStatsService.qml, the same "wrapper script does the real
# work, QML just execs it and parses line-delimited JSON" split every
# other syland-* script in this repo uses.
#
# Loops forever (like `cava` itself does for CavaService.qml), emitting
# one flat JSON object per tick: {"cpu":N,"ram":N,"gpu":N,"temp":N}, all
# integers 0-100 (temp is degrees C, not a percent, but shares the same
# int shape). cpu/ram/temp are read straight from /proc and /sys, no
# root needed. gpu needs config/gpu-stats.nix's own
# security.wrappers.intel_gpu_top (CAP_PERFMON) — reads via that wrapper
# path explicitly, not a bare `intel_gpu_top` off PATH, since the
# unwrapped store binary can't read GPU PMU counters as a normal user
# (confirmed live: "Permission denied" without the wrapper).
{ pkgs, ... }:
let
  sysstats = pkgs.writeShellApplication {
    name = "syland-sysstats";
    runtimeInputs = [ pkgs.gawk pkgs.jq pkgs.coreutils ];
    text = ''
      INTERVAL=2
      GPU_SAMPLE_MS=300
      GPU_TOP=/run/wrappers/bin/intel_gpu_top

      # coretemp's hwmon index isn't stable across reboots/hardware —
      # found by name once at startup, not hardcoded as hwmon5.
      find_coretemp() {
        for h in /sys/class/hwmon/hwmon*; do
          if [ -r "$h/name" ] && [ "$(cat "$h/name")" = "coretemp" ]; then
            echo "$h/temp1_input"
            return 0
          fi
        done
      }
      TEMP_FILE="$(find_coretemp || true)"

      # Standard /proc/stat busy% formula: idle = idle + iowait, busy =
      # everything else in the first (aggregate "cpu") line. Read once
      # up front so the very first tick already has a previous sample to
      # delta against, instead of reporting a meaningless first reading.
      read_cpu_ticks() {
        read -r _ u n s idle iow irq sirq st _ < /proc/stat
        echo "$((u + n + s + irq + sirq + st)) $((idle + iow))"
      }
      read -r prev_busy prev_idle < <(read_cpu_ticks)

      while true; do
        sleep "$INTERVAL"

        read -r busy idle < <(read_cpu_ticks)
        d_busy=$((busy - prev_busy))
        d_total=$((d_busy + idle - prev_idle))
        cpu_pct=0
        [ "$d_total" -gt 0 ] && cpu_pct=$((100 * d_busy / d_total))
        prev_busy=$busy
        prev_idle=$idle

        mem_total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
        mem_avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
        ram_pct=$((100 * (mem_total - mem_avail) / mem_total))

        temp_c=0
        if [ -n "$TEMP_FILE" ] && [ -r "$TEMP_FILE" ]; then
          temp_c=$(($(cat "$TEMP_FILE") / 1000))
        fi

        gpu_pct=0
        if [ -x "$GPU_TOP" ]; then
          # Peak busy% across every reported engine (Render/3D, Video,
          # ...) — the same "how loaded is the GPU right now" figure a
          # single-number readout implies, not an average across engines
          # that mostly sit idle while only one is doing real work.
          gpu_json=$("$GPU_TOP" -J -o - -s "$GPU_SAMPLE_MS" -n 1 2>/dev/null || echo '{}')
          gpu_pct=$(echo "$gpu_json" | jq '([.engines[]?.busy? // 0] | max // 0) | floor' 2>/dev/null || echo 0)
        fi

        jq -nc --argjson cpu "$cpu_pct" --argjson ram "$ram_pct" \
          --argjson gpu "$gpu_pct" --argjson temp "$temp_c" \
          '{cpu: $cpu, ram: $ram, gpu: $gpu, temp: $temp}'
      done
    '';
  };
in
{
  home.packages = [ sysstats ];
}

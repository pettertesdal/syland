pragma Singleton
import QtQuick
import Quickshell.Io

// Drives windows/StatsModule.qml's four readouts from real system load —
// same "long-running wrapper process streams one JSON object per line,
// QML just parses it" shape as services/CavaService.qml, except the
// logic here (delta-based CPU%, coretemp lookup, the intel_gpu_top
// CAP_PERFMON wrapper) is genuinely non-trivial, so unlike cava it goes
// through a real syland-* bridge script (home/syland-sysstats.nix)
// rather than being invoked directly.
//
// Always running (no isActive gate the way cava only runs while music is
// playing) — StatsModule is meant to be glanceable at rest, like a
// taskbar meter, not something that only turns on when explicitly
// opened.
QtObject {
    id: root

    property int cpu: 0
    property int ram: 0
    property int gpu: 0
    property int temp: 0

    property Process proc: Process {
        command: ["syland-sysstats"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (line) {
                if (line.trim().length === 0)
                    return
                var v = JSON.parse(line)
                root.cpu = v.cpu
                root.ram = v.ram
                root.gpu = v.gpu
                root.temp = v.temp
            }
        }
    }
}

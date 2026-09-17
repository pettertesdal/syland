pragma Singleton
import QtQuick
import Quickshell.Io
import "../"

// Drives windows/MusicModule.qml's visualizer bars from real system
// audio output via cava (~/.config/cava/config, deployed as a dotfile by
// home/dotfiles.nix — raw/ascii output mode, one semicolon-delimited
// frame per line, terminated by \n; see that config's own comments for
// the exact directives). Only runs while something's actually playing
// (MprisService.isPlaying) — no point spending CPU on FFT/parsing with
// nothing to visualize, and it doubles as the signal
// windows/MusicModule.qml's own cassette slide-in animation reacts to.
//
// cava is invoked directly here, not through a syland-* wrapper script
// like every other Process in this shell — there's no orchestration or
// logic to hide: its own deployed config file fully determines its
// behavior already, so a wrapper script would just be ceremony around a
// single argument-less command.
QtObject {
    id: root

    readonly property int barCount: 12
    // One entry per bar, 0-100. All zero (flat) whenever cava isn't
    // running, so consumers can render an idle state without a separate
    // "is this even active" check.
    property var bars: new Array(barCount).fill(0)

    property Process proc: Process {
        command: ["cava"]
        running: MprisService.isPlaying

        onRunningChanged: {
            console.log("[Cava] running ->", running)
            if (!running)
                root.bars = new Array(root.barCount).fill(0)
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                console.log("[Cava] line:", JSON.stringify(line))
                var parts = line.split(";").filter(function (s) { return s.length > 0 })
                if (parts.length === root.barCount)
                    root.bars = parts.map(function (s) { return parseInt(s, 10) })
                else
                    console.log("[Cava] unexpected part count:", parts.length, "expected:", root.barCount)
            }
        }
    }

    // Diagnostic only.
    onBarsChanged: console.log("[Cava] bars ->", JSON.stringify(bars))
    Component.onCompleted: console.log("[Cava] MprisService.isPlaying at startup:", MprisService.isPlaying)
}

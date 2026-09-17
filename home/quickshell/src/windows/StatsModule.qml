import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../shapes"
import "../components"

// The two system-stats modules flanking popups/ThemeSwitcher.qml at the
// bottom of the screen — the bottom mirror of windows/MusicModule.qml
// flanking windows/CenterModule.qml's clock at the top. Same box/shape
// split, same align: "left"|"right", but anchors.bottom instead of
// anchors.top and shapes/MusicModuleShape.qml's own flipV: true so the
// flat edge faces the screen's bottom edge and the tail pokes up toward
// popups/ThemeSwitcher.qml instead of down toward it.
//
// No centerModule to key off — there's no bottom-row clock — so instead
// of windows/MusicModule.qml's `centerModule.boxX`/`boxWidth`, this
// centers directly on the screen's own horizontal midpoint with zero
// width, i.e. exactly what MusicModule would do if its centerModule had
// boxWidth: 0. popups/ThemeSwitcher.qml's own panelWidth mirrors this
// same substitution for its own snug-fit sizing.
//
// Four stats (CPU/GPU/RAM/Temp), paired left/right (CPU+RAM, GPU+Temp)
// across each box's two content zones — both zones now identical
// components/StatMeter.qml instances (label above segmented bars); they
// started as asymmetric (outer: plain text, inner: bars-only) before
// converging on the same treatment for every stat.
PanelWindow {
    id: root

    property string align: "left" // "left" | "right"

    readonly property real centerX: root.width / 2

    readonly property int contentPadding: Metrics.spacingMd
    readonly property int dividerGap: Metrics.spacingSm
    readonly property int dividerWidth: 1

    // Shared with every components/StatMeter.qml instance below via
    // explicit binding (not just matching defaults independently) so
    // boxWidth can never drift out of sync with what actually renders.
    readonly property int barCount: 8
    readonly property int barWidth: 8
    readonly property int barSpacing: 2
    readonly property int meterWidth: barCount * barWidth + (barCount - 1) * barSpacing

    readonly property int boxWidth: contentPadding * 2 + meterWidth * 2 + dividerGap * 2 + dividerWidth

    // outerValue/meterValue: which of the four SysStatsService readings
    // lands in which zone — see the file comment above for the pairing.
    readonly property int outerValue: align === "left" ? SysStatsService.cpu : SysStatsService.gpu
    readonly property string outerLabel: align === "left" ? "CPU" : "GPU"
    // Temp (°C) reuses the same 0-100 scale RAM% already is — a rough
    // fit for the range coretemp actually reports (30-90°C).
    readonly property int meterValue: align === "left" ? SysStatsService.ram : SysStatsService.temp
    readonly property string meterLabel: align === "left" ? "RAM" : "TMP"

    anchors { bottom: true; left: true; right: true }
    implicitHeight: Metrics.moduleHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    mask: Region { item: box }

    Item {
        id: box
        width: root.boxWidth
        height: Metrics.moduleContentHeight
        y: parent.height - height
        x: root.align === "left"
            ? root.centerX - width - Metrics.centerGap
            : root.centerX + Metrics.centerGap

        MusicModuleShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: Theme.foreground
            align: root.align
            flipV: true
        }

        StatMeter {
            id: outerMeter
            y: 0
            x: root.align === "left"
                ? root.contentPadding
                : parent.width - root.contentPadding - width
            barCount: root.barCount
            barWidth: root.barWidth
            barSpacing: root.barSpacing
            label: root.outerLabel
            value: root.outerValue
        }

        Rectangle {
            id: divider
            width: root.dividerWidth
            height: parent.height
            y: 0
            x: root.align === "left"
                ? outerMeter.x + outerMeter.width + root.dividerGap
                : outerMeter.x - root.dividerGap - width
            color: Theme.foreground
        }

        StatMeter {
            y: 0
            x: root.align === "left"
                ? divider.x + divider.width + root.dividerGap
                : divider.x - root.dividerGap - width
            barCount: root.barCount
            barWidth: root.barWidth
            barSpacing: root.barSpacing
            label: root.meterLabel
            value: root.meterValue
        }
    }
}

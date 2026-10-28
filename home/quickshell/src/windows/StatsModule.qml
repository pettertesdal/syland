import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
// Left box: focus mode + current project (components/TextMeter.qml,
// label above a short text value). Right box: GPU + Temp
// (components/StatMeter.qml, label above segmented bars) — the system
// stats that still get a bar reading. Both zones share the same
// label-above/content-below footprint regardless of which component
// fills them, so the box/divider layout below doesn't care which is
// which.
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

    // outerValue/outerLabel: GPU reading for the right-hand StatsModule
    // instance. The left instance's own outer zone is a TextMeter
    // (focus mode) instead -- see outerMeter below.
    readonly property int outerValue: SysStatsService.gpu
    readonly property string outerLabel: "GPU"
    // meterValue/meterLabel: Temp (°C) reading for the right-hand
    // instance only now -- the left instance's own inner zone is a
    // TextMeter (current project) instead, see innerMeter below. Temp
    // reuses the same 0-100 scale RAM% used to — a rough fit for the
    // range coretemp actually reports (30-90°C).
    readonly property int meterValue: SysStatsService.temp
    readonly property string meterLabel: "TMP"

    anchors { bottom: true; left: true; right: true }
    implicitHeight: Metrics.moduleHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    mask: Region { item: box }

    // Hidden whenever this module's own monitor has a fullscreen window
    // active -- nothing from quickshell should cover a fullscreen app.
    readonly property bool fullscreenActive: Hyprland.monitorFor(root.screen)?.activeWorkspace?.hasFullscreen === true
    visible: !fullscreenActive

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

        Item {
            id: outerMeter
            y: 0
            x: root.align === "left"
                ? root.contentPadding
                : parent.width - root.contentPadding - width
            width: root.meterWidth
            height: Metrics.moduleContentHeight

            StatMeter {
                anchors.fill: parent
                visible: root.align === "right"
                barCount: root.barCount
                barWidth: root.barWidth
                barSpacing: root.barSpacing
                label: root.outerLabel
                value: root.outerValue
            }

            TextMeter {
                anchors.fill: parent
                visible: root.align === "left"
                label: "MODE"
                value: ShellState.currentMode
            }
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

        Item {
            id: innerMeter
            y: 0
            x: root.align === "left"
                ? divider.x + divider.width + root.dividerGap
                : divider.x - root.dividerGap - width
            width: root.meterWidth
            height: Metrics.moduleContentHeight

            StatMeter {
                anchors.fill: parent
                visible: root.align === "right"
                barCount: root.barCount
                barWidth: root.barWidth
                barSpacing: root.barSpacing
                label: root.meterLabel
                value: root.meterValue
            }

            TextMeter {
                anchors.fill: parent
                visible: root.align === "left"
                label: "PROJECT"
                value: ProjectContextService.projectName
            }
        }
    }
}

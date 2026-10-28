import QtQuick
import "../"

// Bottom-bar replacement for the old CPU meter zone in
// windows/StatsModule.qml -- same label-above/content-below shape as
// components/StatMeter.qml (so it drops into that file's existing
// box/divider layout with no geometry changes), but shows the active
// mode's name instead of a 0-100 bar reading. ShellState.currentMode is
// "" when no mode is active, or the active mode's display label
// otherwise -- adding a future mode is a ShellState.qml change only,
// nothing here needs to change.
Item {
    id: root

    implicitHeight: Metrics.moduleContentHeight

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: "MODE"
        color: Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
        font.letterSpacing: 1
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: ShellState.currentMode !== "" ? ShellState.currentMode : "—"
        color: ShellState.currentMode !== "" ? Theme.accent : Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }
}

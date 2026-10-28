import QtQuick
import "../"

// Same label-above/content-below shape and footprint as StatMeter.qml,
// for a meter slot whose value is a short text string (a mode name, a
// project name, ...) instead of a 0-100 bar reading. Generalized from
// what started as a focus-mode-only ModeIndicator once a second caller
// (windows/StatsModule.qml's own project-name slot) needed the identical
// shape -- label/value/emptyText are props, same as StatMeter's own
// label/value, so each caller supplies its own binding.
Item {
    id: root

    property string label: ""
    property string value: ""
    property string emptyText: "—"

    implicitHeight: Metrics.moduleContentHeight

    Text {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
        font.letterSpacing: 1
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.value !== "" ? root.value : root.emptyText
        color: root.value !== "" ? Theme.accent : Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }
}

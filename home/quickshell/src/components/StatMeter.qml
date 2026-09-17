import QtQuick
import "../"

// A short caps label sitting above a row of segmented level-meter bars —
// windows/StatsModule.qml's own reading for a single 0-100 stat. Pulled
// out once CPU/GPU (plain text before) and RAM/Temp (bars-only before)
// converged on the same shape: every stat gets identical label+bar
// treatment now, so this is one definition used four times (two per
// StatsModule instance) rather than near-duplicate blocks per stat.
Item {
    id: root

    property string label: ""
    property int value: 0 // 0-100

    property int barCount: 8
    property int barWidth: 8
    property int barSpacing: 2
    readonly property int meterWidth: barCount * barWidth + (barCount - 1) * barSpacing

    implicitWidth: meterWidth
    implicitHeight: Metrics.moduleContentHeight

    Text {
        id: labelText
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
        font.letterSpacing: 1
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            delegate: Rectangle {
                required property int index
                readonly property bool lit: index < Math.floor(root.value / 100 * root.barCount)

                width: root.barWidth
                // Whatever's left under the label, within root's own
                // fixed implicitHeight — not a separately-tuned constant
                // that could drift out of sync with labelText's own
                // actual rendered height.
                height: root.height - labelText.height
                color: lit ? Theme.accent : "transparent"
                border.width: 1
                border.color: Theme.accent

                Behavior on color { ColorAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
            }
        }
    }
}

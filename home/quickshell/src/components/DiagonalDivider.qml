import QtQuick
import "../"

// A short diagonal line dropped between segments inside RightModule.qml
// (wifi / bluetooth / battery) — echoes HangingBoxShape's cut-corner angle
// on the inside of the module instead of just the outside. Just a rotated
// 1px Rectangle: no Canvas, no repaint wiring — a declarative `rotation`
// transform is enough for a short straight line.
Item {
    id: root

    property int lineLength: Metrics.moduleHeight * 0.6

    implicitWidth: lineLength * 0.6
    implicitHeight: lineLength

    Rectangle {
        anchors.centerIn: parent
        width: 1
        height: root.lineLength
        color: Theme.foreground
        rotation: 25
    }
}

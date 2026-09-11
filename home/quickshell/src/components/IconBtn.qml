import QtQuick
import "../"

// Generic reusable widget example — not wired up to anything yet, just
// present to show the shape a components/ file should take: it exposes a
// `clicked()` signal and an `icon` property, and reacts to hover/tap
// itself, but never *does* anything on its own — the consumer decides
// what `onClicked:` means (open a popup, run a command, whatever).
Rectangle {
    id: root

    property string icon: ""
    signal clicked()

    implicitWidth: 24
    implicitHeight: 24
    radius: Metrics.cornerRadius
    color: hover.hovered ? Theme.accent : "transparent"

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: Theme.foreground
        font.family: Metrics.fontFamily
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}

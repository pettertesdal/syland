import QtQuick
import Quickshell.Bluetooth
import "../"

// One row in popups/BluetoothPanel.qml's device list — paired or
// discovered-but-unpaired, tap anywhere on the row to do the single most
// relevant action for its current state: pair (not yet paired), connect
// (paired but not connected), or disconnect (already connected).
Item {
    id: root

    required property BluetoothDevice device

    implicitWidth: 320
    implicitHeight: Math.max(nameText.implicitHeight, stateText.implicitHeight) + Metrics.spacingXs * 2

    Text {
        id: nameText
        anchors.left: parent.left
        anchors.right: stateText.left
        anchors.rightMargin: Metrics.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        text: root.device.name.length > 0 ? root.device.name : root.device.deviceName
        color: root.device.connected ? Theme.accent : Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeRegular
        elide: Text.ElideRight
    }

    Text {
        id: stateText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (root.device.connected)
                return root.device.batteryAvailable ? Math.round(root.device.battery * 100) + "%" : "connected"
            return root.device.paired ? "paired" : "pair"
        }
        color: root.device.connected ? Theme.accent : Theme.foreground
        opacity: root.device.connected ? 1 : 0.6
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }

    TapHandler {
        onTapped: {
            if (root.device.connected)
                root.device.disconnect()
            else if (root.device.paired)
                root.device.connect()
            else
                root.device.pair()
        }
    }
}

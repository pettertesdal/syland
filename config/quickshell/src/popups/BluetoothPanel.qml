import QtQuick
import Quickshell.Bluetooth
import "../"
import "../components"
import "../shapes"

// windows/RightModule.qml "growing" into advanced bluetooth options —
// same shapes/SeamPanelShape.qml popups/NotificationCenter.qml uses, so
// it reads as an extension of RightModule rather than an unrelated popup.
// Adapter power and scan are the two global toggles
// services/BluetoothStatusService.qml owns; everything per-device (pair/
// connect/disconnect) is a plain method call on the device object itself,
// via components/BluetoothDeviceRow.qml.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.bluetoothPanelOpen
    onCloseRequested: Popups.bluetoothPanelOpen = false

    readonly property int panelWidth: 380
    readonly property int panelHeight: 420

    Item {
        id: panel
        width: root.panelWidth
        height: root.panelHeight
        x: root.openFlag ? (parent.width - width) : parent.width
        Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        SeamPanelShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: Theme.foreground
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: header
            anchors.top: parent.top
            // The shape's own top edge sits at Metrics.moduleHeight for
            // almost its whole width — see SeamPanelShape.qml.
            anchors.topMargin: Metrics.moduleHeight + Metrics.spacingMd
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Metrics.spacingMd
            spacing: Metrics.spacingSm

            Item {
                width: parent.width
                height: titleText.implicitHeight

                Text {
                    id: titleText
                    text: "Bluetooth"
                    color: Theme.foreground
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeLarge
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: BluetoothStatusService.enabled ? "on" : "off"
                    color: BluetoothStatusService.enabled ? Theme.accent : Theme.red
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall

                    TapHandler { onTapped: BluetoothStatusService.toggleAdapter() }
                }
            }

            Item {
                width: parent.width
                height: scanText.implicitHeight
                visible: BluetoothStatusService.enabled

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "devices"
                    color: Theme.foreground
                    opacity: 0.6
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall
                }

                Text {
                    id: scanText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: BluetoothStatusService.discovering ? "scanning..." : "scan"
                    color: BluetoothStatusService.discovering ? Theme.accent : Theme.foreground
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall

                    TapHandler { onTapped: BluetoothStatusService.toggleDiscovery() }
                }
            }
        }

        ListView {
            anchors.top: header.bottom
            anchors.topMargin: Metrics.spacingSm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.spacingMd
            clip: true
            spacing: Metrics.spacingXs
            visible: BluetoothStatusService.enabled
            model: Bluetooth.devices

            delegate: BluetoothDeviceRow {
                // Same required-property pattern popups/NotificationCenter.qml's
                // ListView needs — this file is nested inside shell.qml's
                // per-screen `Scope { required property var modelData }`,
                // which shadows a bare implicit modelData reference.
                required property var modelData

                width: ListView.view.width
                device: modelData
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !BluetoothStatusService.enabled
            text: "Bluetooth is off"
            color: Theme.foreground
            opacity: 0.6
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeRegular
        }
    }
}

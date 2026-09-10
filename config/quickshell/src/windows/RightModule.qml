import QtQuick
import Quickshell.Bluetooth
import "../"
import "../components"
import "../modules"

// The right hanging module: wifi / bluetooth / battery, separated by
// DiagonalDivider (echoes HangingBoxShape's own cut-corner angle on the
// inside of the module) — and, triggered by Popups.bluetoothPanelOpen,
// this same window grows into an advanced bluetooth panel (adapter
// power, scan, device list) rather than a separate popup appearing
// elsewhere. See components/HangingModule.qml for why growing in place
// beats a second window trying to line up with this one.
HangingModule {
    id: root

    align: "right"
    boxWidth: statusRow.implicitWidth + Metrics.spacingMd * 2

    grown: Popups.bluetoothPanelOpen
    grownWidth: 380
    grownHeight: 420

    // The mini status row — fades out as the panel grows.
    Item {
        anchors.fill: parent
        opacity: root.grown ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Metrics.animDuration * 0.5; easing.type: Easing.Linear } }

        Row {
            id: statusRow
            anchors.centerIn: parent
            spacing: Metrics.spacingSm

            WifiIndicator {}
            DiagonalDivider {}
            BluetoothIndicator {}
            DiagonalDivider {}
            BatteryIndicator {}
        }
    }

    // The expanded bluetooth panel — fades in as the module grows.
    // Adapter power and scan are the two global toggles
    // services/BluetoothStatusService.qml owns; everything per-device
    // (pair/connect/disconnect) is a plain method call on the device
    // object itself, via components/BluetoothDeviceRow.qml.
    Item {
        anchors.fill: parent
        opacity: root.grown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.grown ? Metrics.animDuration * 0.5 : Metrics.animDuration * 0.15 } }

        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
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
            clip: true
            spacing: Metrics.spacingXs
            visible: BluetoothStatusService.enabled
            model: Bluetooth.devices

            delegate: BluetoothDeviceRow {
                // This file is nested inside shell.qml's per-screen
                // `Scope { required property var modelData }`, which
                // shadows a bare implicit modelData reference — same fix
                // popups/NotificationCenter.qml needed.
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

import QtQuick
import Quickshell.Bluetooth
import "../"
import "../components"
import "../shapes"

// Bluetooth panel — replaces windows/RightModule.qml's old "grow in place"
// mechanic with a real popup, same SeamPanelShape/settle-motion/flash
// pattern as popups/NotificationCenter.qml (which this is a structural
// twin of: same width, same right-flush x, same top-right notch sharing
// RightModule's corner diagonal) — except the open/close motion animates
// y instead of x. Closed sits fully above the screen (y: -height);
// open drops down to rest at y: 0, landing right where RightModule's own
// bottom-right corner (and the notification light next to it) already
// is, rather than sliding in from the side.
//
// Content is a straight port of RightModule's old "grown" Bluetooth
// section (adapter toggle, scan, device list) — no new backend, wifi/
// battery are still just icons elsewhere for now.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.bluetoothPanelOpen
    onCloseRequested: Popups.bluetoothPanelOpen = false

    readonly property int panelWidth: 380

    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                closeAnim.stop()
                panel.beginOpen()
            } else {
                openAnim.stop()
                pendingOpen.enabled = false
                closeAnim.restart()
            }
        }
    }

    Item {
        id: panel
        width: root.panelWidth
        // Same "leave a gap matching the panel's own width" reasoning as
        // NotificationCenter, just at the top instead of the bottom.
        height: parent.height - root.panelWidth
        x: parent.width - width

        readonly property int restY: 0
        readonly property int hiddenY: -height
        y: hiddenY

        SequentialAnimation {
            id: openAnim
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "y"
                to: panel.restY + Metrics.settleOvershoot
                duration: Metrics.animDuration
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: panel; property: "y"
                to: panel.restY
                duration: Metrics.settleDuration
                easing.type: Easing.Linear
            }
        }

        NumberAnimation {
            id: closeAnim
            target: panel; property: "y"
            to: panel.hiddenY
            duration: Metrics.animDuration
            easing.type: Easing.Linear
        }

        // Same first-open geometry-race guard as TodoPanel/NotificationCenter
        // (see their comments for the full reasoning) — parent.height, not
        // parent.width, since this panel's hidden position depends on its
        // own height, not the screen's width.
        function beginOpen() {
            if (parent.height >= height) {
                openAnim.restart()
            } else {
                pendingOpen.enabled = true
            }
        }

        Connections {
            id: pendingOpen
            target: panel.parent
            enabled: false
            function onHeightChanged() {
                if (root.openFlag && panel.parent.height >= panel.height) {
                    pendingOpen.enabled = false
                    openAnim.restart()
                }
            }
        }

        property color borderColor: Theme.foreground

        function flashBorder() {
            flashFade.stop()
            borderColor = Theme.accent
            flashFade.restart()
        }

        ColorAnimation {
            id: flashFade
            target: panel; property: "borderColor"
            to: Theme.foreground
            duration: Metrics.settleDuration * 3
            easing.type: Easing.Linear
        }

        SeamPanelShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: panel.borderColor
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: header
            anchors.top: parent.top
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

import QtQuick
import Quickshell.Bluetooth
import "../"
import "../components"
import "../shapes"

// Bluetooth panel — replaces windows/RightModule.qml's old "grow in
// place" mechanic with a real popup. Shaped by shapes/BluetoothPanelShape.qml:
// a narrow top section that exactly coincides with RightModule's own
// resting silhouette (same width, same right-edge inset), widening below
// Metrics.moduleHeight into the full panel body — see that shape's own
// header comment for the full geometry reasoning. Because the narrow top
// is meant to be motionless (it's just echoing RightModule, which never
// moves), what animates on open/close is *height*, not position: closed,
// height sits at Metrics.moduleHeight and the shape degenerates to
// exactly RightModule's own rectangle (nothing new drawn); open, it
// grows down to reveal the wide body. x/y/width stay constant throughout.
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

    // The RightModule instance this panel's narrow top section has to
    // exactly coincide with — passed in from shell.qml, since that's a
    // sibling window, not something reachable any other way. Falls back
    // to a reasonable default so this doesn't error before shell.qml is
    // updated to actually pass it.
    property var rightModule: null
    readonly property int topWidth: rightModule ? rightModule.boxWidth : 150

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
        x: parent.width - width
        y: 0

        readonly property int restHeight: parent.height - root.panelWidth
        readonly property int hiddenHeight: Metrics.moduleHeight
        height: hiddenHeight

        SequentialAnimation {
            id: openAnim
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "height"
                to: panel.restHeight + Metrics.settleOvershoot
                duration: Metrics.animDuration
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: panel; property: "height"
                to: panel.restHeight
                duration: Metrics.settleDuration
                easing.type: Easing.Linear
            }
        }

        NumberAnimation {
            id: closeAnim
            target: panel; property: "height"
            to: panel.hiddenHeight
            duration: Metrics.animDuration
            easing.type: Easing.Linear
        }

        // Same first-open geometry-race guard as TodoPanel/NotificationCenter
        // (see their comments for the full reasoning) — parent.height,
        // since restHeight depends on it.
        function beginOpen() {
            if (parent.height >= root.panelWidth + Metrics.moduleHeight) {
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
                if (root.openFlag && panel.parent.height >= root.panelWidth + Metrics.moduleHeight) {
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

        BluetoothPanelShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: panel.borderColor
            chamfer: Metrics.chamferSize
            topWidth: root.topWidth
            topInset: Metrics.moduleMargin
            topHeight: Metrics.moduleHeight
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
            visible: panel.height > Metrics.moduleHeight + Metrics.spacingMd

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
            visible: BluetoothStatusService.enabled && header.visible
            model: Bluetooth.devices

            delegate: BluetoothDeviceRow {
                required property var modelData
                width: ListView.view.width
                device: modelData
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !BluetoothStatusService.enabled && header.visible
            text: "Bluetooth is off"
            color: Theme.foreground
            opacity: 0.6
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeRegular
        }
    }
}

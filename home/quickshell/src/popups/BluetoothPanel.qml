import QtQuick
import Quickshell.Bluetooth
import "../"
import "../components"
import "../shapes"

// Bluetooth panel — replaces windows/RightModule.qml's old "grow in
// place" mechanic with a real popup. Shaped by shapes/BluetoothPanelShape.qml:
// a plain rectangle top with chamfered bottom corners, stepping in around
// windows/NotificationLight.qml's own tab further down — see that shape's
// own header comment for the full geometry reasoning. What animates on
// open/close is *height*, not position: closed, height sits at 0
// (nothing drawn); open, it grows down from the screen's top-right
// corner. x/y/width stay constant throughout. RightModule no longer
// needs to be impersonated while closed (it used to be, via a narrow top
// section matching its own silhouette) since it now rides down with this
// panel as it opens instead — its own yShift/maxYShift, same mechanism
// windows/CenterModule.qml uses for popups/Picker.qml.
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

    // windows/NotificationLight.qml — same cross-window reference
    // pattern popups/BluetoothPanel.qml's own sibling windows use
    // elsewhere in this shell (e.g. windows/MusicModule.qml's
    // centerModule), passed in from shell.qml. Its own tabDepth/shift/
    // lightTopY are plain readonly properties, already externally
    // reachable with no separate "public" surface needed.
    // notificationLightX is the light's own width (tabDepth) plus
    // however far left it's currently shifted (shift, nonzero only
    // while NotificationCenter is also open) — the total distance
    // shapes/BluetoothPanelShape.qml's own right edge has to stay clear
    // of, not just the light's static resting width.
    property var notificationLight: null
    readonly property real notificationLightX: notificationLight ? notificationLight.tabDepth + notificationLight.shift : 10
    readonly property real notificationLightY: notificationLight ? notificationLight.lightTopY : 200

    // 0 when fully closed (height at hiddenHeight), 1 when fully settled
    // open (height at restHeight) — windows/RightModule.qml reads this to
    // ride down in sync, exactly like windows/CenterModule.qml's own
    // openProgress read of popups/Picker.qml.
    readonly property real openProgress: panel.restHeight > panel.hiddenHeight
        ? (panel.height - panel.hiddenHeight) / (panel.restHeight - panel.hiddenHeight)
        : 0
    // How far RightModule rides down at full open — the panel's own full
    // growth range, same "travel the whole distance, not a capped
    // fraction" parity windows/CenterModule.qml's own comment already
    // established for Picker's clock.
    readonly property real growthRange: panel.restHeight - panel.hiddenHeight

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

        // Was parent.height - root.panelWidth (~700px on a 1080-tall
        // screen) — a fixed, shorter constant instead now that nothing
        // ties this panel's own height to its width; confirmed live that
        // formula read as much too tall for a short device list.
        readonly property int restHeight: 340
        // Was Metrics.moduleHeight (matching the old narrow-top's own
        // resting height) — genuinely 0 now that there's no narrow top
        // section for this to degenerate into anymore.
        readonly property int hiddenHeight: 0
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
        // (see their comments for the full reasoning) — parent.height
        // sits at a placeholder (100) until this window's first real
        // Wayland configure, well under restHeight, so this correctly
        // defers until it's a real screen height.
        function beginOpen() {
            if (parent.height >= panel.restHeight) {
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
                if (root.openFlag && panel.parent.height >= panel.restHeight) {
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
            notificationLightX: root.notificationLightX
            notificationLightY: root.notificationLightY
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: header
            // Was Metrics.moduleHeight + spacingMd (clearing the old
            // narrow top section) — plain spacingMd now, flush near the
            // top like every other panel's own content inset.
            anchors.top: parent.top
            anchors.topMargin: Metrics.spacingMd
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Metrics.spacingMd
            // Extra clearance on top of the plain spacingMd every other
            // edge uses — shapes/BluetoothPanelShape.qml's own right edge
            // steps in by this same notificationLightX past
            // notificationLightY, so content needs the same reservation
            // to not run into that notch once it grows tall/wide enough
            // to reach that Y, not just happen to fit today because the
            // list is short.
            anchors.rightMargin: Metrics.spacingMd + root.notificationLightX
            spacing: Metrics.spacingSm
            // Same threshold, just no longer keyed to the narrow top's
            // own height specifically — still "opened enough to actually
            // show content," not tied to a section that no longer exists.
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
            // Same notificationLightX reservation as header above.
            anchors.rightMargin: Metrics.spacingMd + root.notificationLightX
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

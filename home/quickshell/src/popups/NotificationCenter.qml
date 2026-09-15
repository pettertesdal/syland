import QtQuick
import "../"
import "../components"
import "../shapes"

// The notification history panel: full screen width and height, sliding
// in from the right and back out, showing every notification currently
// tracked by services/NotificationService.qml. Independent of
// popups/NotificationToast.qml: a notification can have already
// auto-dismissed as a toast and still show up here, since tracking and
// toast-display are two separate lifetimes on the same underlying
// NotificationServer.
//
// Shaped by shapes/SeamPanelShape.qml (shared with popups/BluetoothPanel.qml):
// a fixed-width column (not the whole screen), flush against the screen's
// true right edge and true bottom edge, with a notch cut into the
// top-right area that shares its diagonal exactly with
// windows/RightModule.qml's own bottom-right corner — see that shape's own
// comment for the geometry. The Canvas math there is relative to the
// panel's own width/height, so it stays correct regardless of panelWidth
// as long as the panel's right edge stays flush against the screen's
// right edge when open (x: parent.width - panelWidth).
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.notificationCenterOpen
    onCloseRequested: Popups.notificationCenterOpen = false

    readonly property int panelWidth: 380

    // Settle motion + actuation flash + first-open geometry-race guard —
    // ported verbatim from popups/TodoPanel.qml (the pilot for this
    // pattern) once it was confirmed working live there. See that file's
    // own comments for the full reasoning behind each piece; kept
    // identical here rather than re-explained, since this is a straight
    // port of the same x-slide-from-right geometry, not an adaptation.
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
        // A gap between the panel's bottom and the screen's true bottom
        // edge, sized to match the panel's own width.
        height: parent.height - root.panelWidth

        readonly property int restX: parent.width - width
        readonly property int hiddenX: parent.width
        x: hiddenX

        SequentialAnimation {
            id: openAnim
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "x"
                to: panel.restX - Metrics.settleOvershoot
                duration: Metrics.animDuration
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: panel; property: "x"
                to: panel.restX
                duration: Metrics.settleDuration
                easing.type: Easing.Linear
            }
        }

        NumberAnimation {
            id: closeAnim
            target: panel; property: "x"
            to: panel.hiddenX
            duration: Metrics.animDuration
            easing.type: Easing.Linear
        }

        function beginOpen() {
            if (parent.width >= width) {
                openAnim.restart()
            } else {
                pendingOpen.enabled = true
            }
        }

        Connections {
            id: pendingOpen
            target: panel.parent
            enabled: false
            function onWidthChanged() {
                if (root.openFlag && panel.parent.width >= panel.width) {
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
            // The shape's own top edge sits at Metrics.moduleHeight for
            // almost its whole width (see NotificationPanelShape.qml) —
            // content has to clear that, not just y=0, or it'd render in
            // the transparent notch area above the visible fill.
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
                    text: "Notifications"
                    color: Theme.foreground
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeLarge
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: NotificationService.server.trackedNotifications.count > 0
                    text: "clear all"
                    color: Theme.accent
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall

                    TapHandler {
                        onTapped: {
                            var tracked = NotificationService.server.trackedNotifications
                            for (var i = tracked.count - 1; i >= 0; i--)
                                tracked.get(i).dismiss()
                        }
                    }
                }
            }

            Text {
                visible: NotificationService.server.trackedNotifications.count === 0
                text: "No notifications"
                color: Theme.foreground
                opacity: 0.6
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeRegular
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
            spacing: Metrics.spacingSm
            model: NotificationService.server.trackedNotifications

            delegate: NotificationCard {
                // required property, not a bare `modelData` reference —
                // this file sits nested inside shell.qml's per-screen
                // `Scope { required property var modelData }` (the
                // QuickshellScreenInfo from Variants), which shadows a
                // ListView's own implicit modelData if the delegate
                // doesn't explicitly re-declare it. Same pattern
                // windows/LeftModule.qml and popups/NotificationToast.qml
                // already use for exactly this reason.
                required property var modelData

                width: ListView.view.width
                notification: modelData
                // The panel itself already has a border — individually
                // boxing every row would just nest rectangles. Rows are
                // separated by the ListView's own spacing instead.
                bordered: false
            }
        }
    }
}

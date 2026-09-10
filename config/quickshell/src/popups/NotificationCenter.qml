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
// Shaped by shapes/NotificationPanelShape.qml: flush against the screen's
// true left and right edges, except one notch cut into the top-right area
// that shares its diagonal exactly with windows/RightModule.qml's own
// bottom-right corner — see that shape's own comment for the geometry.
// Because the panel is genuinely full-width now (not a fixed 360px
// column), `panel` doesn't need its own width property — it's always
// parent.width, and the slide is just `x` between parent.width
// (off-screen) and 0 (flush against the true left edge, open).
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.notificationCenterOpen
    onCloseRequested: Popups.notificationCenterOpen = false

    Item {
        id: panel
        width: parent.width
        height: parent.height
        x: root.openFlag ? 0 : parent.width
        Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        NotificationPanelShape {
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

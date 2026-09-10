import QtQuick
import "../"
import "../components"

// The notification history panel: a full-height sidebar that slides in
// from the right edge and back out, showing every notification currently
// tracked by services/NotificationService.qml. Independent of
// popups/NotificationToast.qml: a notification can have already
// auto-dismissed as a toast and still show up here, since tracking and
// toast-display are two separate lifetimes on the same underlying
// NotificationServer.
//
// Unlike ExamplePanel this doesn't grow/shrink — `panel` is always
// panelWidth wide and the screen's full height, and the only thing that
// animates is its own x position sliding linearly between off-screen
// (parent.width) and flush against the right edge (parent.width -
// panelWidth). AnimatedPopup still supplies the show/hide-with-
// animation-finish timing, just not any of the geometry.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.notificationCenterOpen
    onCloseRequested: Popups.notificationCenterOpen = false

    readonly property int panelWidth: 360

    Rectangle {
        id: panel
        width: root.panelWidth
        height: parent.height
        x: root.openFlag ? (parent.width - width) : parent.width
        Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        color: Theme.background
        border.width: 1
        border.color: Theme.foreground

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: header
            anchors.top: parent.top
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

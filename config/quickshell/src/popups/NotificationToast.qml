import QtQuick
import "../"
import "../components"

// Transient corner toasts — auto-appear when NotificationService receives
// a notification, auto-disappear once services/NotificationService.qml
// prunes them out of its toastQueue after toastDuration. Unlike
// ExamplePanel/NotificationCenter this doesn't melt into the border (a
// corner-anchored stack doesn't share their bottom-edge geometry), and
// there's no click-outside dismiss — closeRequested() is left unhandled
// on purpose, since toasts are meant to go away on their own, not be
// clicked shut.
//
// Reuses AnimatedPopup purely for its windowVisible/closeTimer show-hide
// mechanics (driven here by "is the queue non-empty" instead of a
// Popups.* flag) and NotificationCard for each entry, same as
// NotificationCenter — the shared pieces are what keep a toast and a
// history-panel entry looking and animating like the same system.
AnimatedPopup {
    id: root

    anchors { top: true; right: true }
    openFlag: NotificationService.toastQueue.length > 0

    implicitWidth: 340
    implicitHeight: stack.implicitHeight + Metrics.spacingMd * 2

    Column {
        id: stack
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Metrics.spacingMd
        spacing: Metrics.spacingSm

        Repeater {
            model: NotificationService.toastQueue

            delegate: NotificationCard {
                required property var modelData
                width: 320
                notification: modelData.notification

                opacity: root.openFlag ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Metrics.animDuration * 0.5 } }
            }
        }
    }
}

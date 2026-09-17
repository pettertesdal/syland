pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// Owns the one NotificationServer instance for the whole shell — same
// reasoning as state/IpcManager.qml: instantiating this per-screen (e.g.
// inside a window that's created once per monitor via shell.qml's
// Variants) would register the DBus org.freedesktop.Notifications service
// more than once. Force this singleton to instantiate eagerly from
// shell.qml the same way IpcManager already is.
//
// Every incoming notification is immediately marked `tracked = true` so
// it stays in `server.trackedNotifications` for popups/NotificationCenter.qml
// to show as history, independent of how long it's shown as a toast.
// `toastQueue` is this shell's own separate, short-lived view of "what
// should currently render as a toast" — entries get pruned out of it once
// `toastDuration` elapses, without ever calling dismiss()/expire() on the
// underlying notification, so it can still be dismissed as read but keep
// existing in the center.
QtObject {
    id: root

    readonly property int toastDuration: 5000

    // How many notifications existed the last time
    // popups/NotificationCenter.qml was closed — i.e. how many you've
    // actually seen. Lives here, not on the popup itself, so
    // windows/NotificationLight.qml (a separate, always-visible window
    // with no notion of the popup's own internal state) can read it too
    // for its own unread/clear indicator. Starts at 0, so anything
    // present before the panel's ever been opened correctly counts as
    // unseen.
    property int seenCount: 0

    // Array of { notification, shownAt } — reassigned wholesale (concat/
    // filter, never push/splice) since QML only notifies bindings on
    // whole-property assignment for `property var`, not in-place mutation.
    property var toastQueue: []

    function _pruneExpiredToasts() {
        var now = Date.now()
        var next = toastQueue.filter(function (entry) {
            return now - entry.shownAt < toastDuration
        })
        if (next.length !== toastQueue.length)
            toastQueue = next
    }

    property Timer pruneTimer: Timer {
        interval: 250
        running: root.toastQueue.length > 0
        repeat: true
        onTriggered: root._pruneExpiredToasts()
    }

    readonly property NotificationServer server: NotificationServer {
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            root.toastQueue = root.toastQueue.concat([{ notification: notification, shownAt: Date.now() }])

            // Dismissed/expired elsewhere (e.g. from the center, or by the
            // sender) — drop it from the toast queue immediately instead
            // of waiting out the rest of toastDuration on a stale toast.
            notification.closed.connect(function () {
                root.toastQueue = root.toastQueue.filter(function (entry) {
                    return entry.notification !== notification
                })
            })
        }
    }
}

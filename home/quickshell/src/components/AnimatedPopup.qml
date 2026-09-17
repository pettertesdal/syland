import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// Shared open/close motion, extracted from popups/ExamplePanel.qml once
// NotificationCenter/NotificationToast needed the exact same mechanics.
//
// What this owns: the windowVisible/closeTimer trick — `visible` flips
// true immediately on open, but only flips back to false once closeTimer
// gives the shrink/fade animation time to finish (cutting `visible` early
// would tear the window down mid-animation, the same NaN-interval bug
// this shell hit before Metrics.animDuration existed) — plus the
// transparent/overlay-layer window defaults every popup wants, and a
// closeRequested() signal for "user clicked outside."
//
// What this deliberately does NOT own: sizing/positioning of the actual
// content (a bottom-anchored panel, a full-height sliding sidebar, and a
// corner-anchored toast stack are different enough shapes that forcing
// one geometry on all of them would be more contortion than reuse), and
// anchors (set these per consumer — a border-anchored panel spans the
// whole screen, a toast doesn't).
//
// Usage: bind `openFlag` to whatever bool drives this popup (a Popups.*
// flag, or anything else), put your own sized/positioned content inside
// (it becomes a child of the always-full-size contentItem for free), and
// handle `closeRequested()` however makes sense for your flag — usually
// `onCloseRequested: Popups.xxxOpen = false`. openFlag is normally a
// one-way binding from outside, so this component can't flip it itself.
PanelWindow {
    id: root

    property bool openFlag: false
    default property alias content: contentItem.data

    signal closeRequested()

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    property bool keepVisible: false
    property bool windowVisible: false
    visible: windowVisible || keepVisible

    onOpenFlagChanged: {
        if (openFlag) {
            closeTimer.stop()
            root.windowVisible = true
        } else {
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: Metrics.animDuration + 20
        onTriggered: if (!root.openFlag) root.windowVisible = false
    }

    // Click anywhere in the window to request a close — what that means
    // is up to the consumer (see closeRequested() above).
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}

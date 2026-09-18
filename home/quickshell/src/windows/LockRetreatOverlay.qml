import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../"

// The "look-alike lock" half of the unlock handoff — see
// home/quickshell-lock/LockContext.qml's own comment for the other half,
// and home/quickshell-lock/shell.qml's for why the real lock can't just
// play this same retreat on its own surface: WlSessionLock.locked = false
// is unlock_and_destroy under the hood, so the instant the real lock (a
// totally separate process) unlocks, its WlSessionLockSurface is torn
// down immediately — there's no "unlocked but still animating" state to
// land in.
//
// This window is the workaround: a plain (non-session-locked) full-
// screen overlay living in the main shell, which never gets torn down by
// an unlock, pre-built to look EXACTLY like the real lock's own resting
// state — panel shapes, colors, and geometry all ported from
// LockSurface.qml. Kept as a genuine separate copy rather than a shared
// component: the two live in independently-deployed config trees (see
// home/dotfiles.nix's own theme/ dual-deployment for the same boundary),
// and true sharing would mean a third cross-tree deployment just for
// this one pair of files.
//
// The real lock triggers this (`qs ipc call lock-retreat show`, fired by
// LockContext.qml's own Process) in the same instant it unlocks, so the
// swap from "real lock, resting" to "this window, resting" is
// imperceptible — and the real unlock is never gated on it: if this
// process isn't even running, the IPC call just fails silently and the
// real lock still unlocks immediately regardless (see LockContext.qml's
// own comment on why that's deliberate).
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: shown

    // Direct binding + a Connections on root's own openFlag, not
    // `Connections { target: Popups }` — matches every other popup in
    // this shell (see popups/TodoPanel.qml's own openFlag: Popups.xxxOpen
    // plus its own `Connections { target: root }`), a pattern already
    // proven to work; listening to the singleton directly was untested
    // and turned out not to fire at all — confirmed live, the overlay
    // never mapped (checked via `hyprctl layers`, no new surface at all).
    property bool openFlag: Popups.lockRetreatOpen
    property bool shown: false

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real halfBoxW: Metrics.lockBoxWidth / 2
    readonly property real tabDepth: Metrics.lockBoxHeight / 2
    // Same reasoning as LockSurface.qml's own travel — a fixed pixel
    // distance can't guarantee "fully past any edge" across differently
    // sized monitors, so it's derived from this window's own width/height.
    readonly property real travel: Math.max(width, height) * 1.1
    readonly property color plateFill: Qt.darker(Theme.background, 1.15)

    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                root.shown = true
                retreatAnimation.start()
            }
        }
    }

    // No base Rectangle backstop here, unlike LockSurface.qml's own copy
    // of this layout — that one needs it (WlSessionLockSurface's content
    // isn't guaranteed opaque before its own entrance animation finishes
    // covering the screen, a real security/flash concern). This window
    // has neither problem: its six panels are already fully resting/
    // covering the instant it appears, with no entrance motion to guard,
    // so a backstop here was pure dead weight — confirmed live, its only
    // effect was becoming visible as a plain, un-bordered 7th panel for
    // a moment once the last diagonal panel actually retreated.
    //
    // All six panels below are declared already at rest (x/y default to
    // 0) — this window never plays an entrance, it just appears already
    // assembled, matching whatever the real lock looked like the instant
    // before it was destroyed.
    Shape {
        id: panelTL
        width: root.width; height: root.height
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        id: panelBR
        width: root.width; height: root.height
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: root.width; startY: 0
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: root.width; y: 0 }
        }
    }

    Shape {
        id: panelBL
        width: root.width; height: root.height
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: 0; y: root.height }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        id: panelTR
        width: root.width; height: root.height
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        id: barTop
        width: root.width; height: root.height
        ShapePath {
            fillColor: Theme.background
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.cy }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx - root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx - root.halfBoxW; y: root.cy }
            PathLine { x: 0; y: root.cy }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        id: barBottom
        width: root.width; height: root.height
        ShapePath {
            fillColor: Theme.background
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: root.cy
            PathLine { x: root.cx - root.halfBoxW; y: root.cy }
            PathLine { x: root.cx - root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy }
            PathLine { x: root.width; y: root.cy }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: root.cy }
        }
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000
        running: root.shown
        repeat: true
        onTriggered: now = new Date()
    }

    // No password field — auth already succeeded before this window ever
    // shows. Clock/date match the real lock's own content exactly (same
    // fonts/sizes) so the swap has nothing visibly different to give it
    // away; the box below stays empty rather than trying to replicate
    // whatever the password field happened to show mid-typing.
    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: Metrics.spacingLg

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clockTimer.now, "hh:mm")
            color: Theme.foreground
            font.family: Metrics.fontFamily
            font.pixelSize: 64
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clockTimer.now, "dddd, d MMMM")
            color: Theme.foreground
            opacity: 0.7
            font.family: Metrics.fontFamily
            font.pixelSize: Metrics.fontSizeRegular
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: Metrics.moduleHeight
            color: Theme.background
            border.width: 1
            border.color: Theme.foreground
        }
    }

    // Same shape as LockSurface.qml's own (now-removed) unlockAnimation:
    // content fades first, then the panels peel off in reverse order
    // (last-in, first-out) — bars, then pair 2, then pair 1 — revealing
    // the real desktop underneath, which by this point has actually been
    // unlocked and live the entire time this window has been showing.
    SequentialAnimation {
        id: retreatAnimation
        running: false

        NumberAnimation { target: contentColumn; property: "opacity"; to: 0; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }

        ParallelAnimation {
            NumberAnimation { target: barTop; property: "y"; to: -root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: barBottom; property: "y"; to: root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
        }

        ParallelAnimation {
            NumberAnimation { target: panelBL; property: "x"; to: -root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelBL; property: "y"; to: root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelTR; property: "x"; to: root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelTR; property: "y"; to: -root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
        }

        ParallelAnimation {
            NumberAnimation { target: panelTL; property: "x"; to: -root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelTL; property: "y"; to: -root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelBR; property: "x"; to: root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
            NumberAnimation { target: panelBR; property: "y"; to: root.travel; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
        }

        // Resets everything back to resting so the next trigger starts
        // clean rather than mid-retreat from last time — this window's
        // own QML instance stays alive the whole session, unlike the
        // real lock's own process, which gets a fresh one every time.
        onFinished: {
            root.shown = false
            Popups.lockRetreatOpen = false
            contentColumn.opacity = 1
            panelTL.x = 0; panelTL.y = 0
            panelBR.x = 0; panelBR.y = 0
            panelBL.x = 0; panelBL.y = 0
            panelTR.x = 0; panelTR.y = 0
            barTop.y = 0
            barBottom.y = 0
        }
    }
}

import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import "./theme"

// The actual visual lock screen, one instance per WlSessionLockSurface
// (one per monitor) — clock, password field, wrong-password flash, and
// (sometimes) the six-panel mechanical assembly animation on lock. Same
// straight-edge/mechanical visual language as the main shell (no
// cornerRadius, ProggyClean, Theme/Metrics tokens throughout), but
// deliberately self-contained: no clock/service singletons reached in
// from home/quickshell/src/ beyond theme/ itself (see home/dotfiles.nix's
// own comment on why that boundary is explicit), so this keeps working
// even if the main shell's own process is down.
//
// "Sometimes" because this surface has two different entrances depending
// on how it was triggered:
//
// - home/hypr/base.lua's own boot-time first lock, and hypridle's own
//   lock_cmd/before_sleep_cmd (home/hypr/hypridle.conf) start
//   syland-lock.service directly — this surface maps with nothing shown
//   yet and plays the six-panel entrance below itself, same as it always
//   did.
// - home/syland-lock-trigger.nix's own script (the keybind, and
//   hypridle's idle-timeout) plays that *same* entrance first on the
//   main shell's own windows/LockAssemblyOverlay.qml instead — a normal
//   window, not a session lock, so it can only run *before* this surface
//   exists at all (a WlSessionLockSurface is guaranteed by the
//   compositor to render above everything, so nothing can ever animate
//   on top of one once it's mapped — confirmed live, see that file's own
//   comment). That overlay writes a marker file right before starting
//   syland-lock.service once its own copy of the animation finishes, so
//   this surface knows to skip playing the *same* entrance a second time
//   and just show everything already resting instead — otherwise the
//   user would see the entrance play twice in a row.
//
// The six panels themselves: a rectangle has exactly two diagonals, each
// splitting it into two triangles that together exactly tile it. Panel
// pair 1 (panelTL/panelBR) is the split along the top-right/bottom-left
// diagonal — the "top-left" and "bottom-right" names refer to which
// single corner each triangle owns as its odd vertex out, not the seam
// itself. Pair 2 (panelBL/panelTR) is necessarily the OTHER diagonal's
// split, for the same reason. Both pairs independently tile the whole
// screen — pair 2 fully overlaps pair 1 once both are resting, which
// reads as a second layer of plating snapping down rather than revealing
// new area, deliberately (an empty-handed "efficient" tiling would need
// each pair to only cover half the screen, but the brief was "mechanical
// armor plates locking down," not minimal coverage). Pair 3 (the top/
// bottom bars) is the final, topmost layer and is what's actually still
// visible once everything settles — its tab/notch key is what frames the
// login content, everything underneath is fully hidden by its opaque
// fill by then.
//
// Every panel's own path coordinates are baked as its true resting shape
// in absolute (0,0)-(width,height) screen space — entry is always a pure
// rigid-body translate of the whole Shape item back to (0,0), never a
// reshape, so the vertex math only has to happen once per panel rather
// than once per animation frame.
Item {
    id: root

    property var context: null
    property bool assembled: false

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real halfBoxW: Metrics.lockBoxWidth / 2
    readonly property real tabDepth: Metrics.lockBoxHeight / 2

    // How far off-screen each panel starts, in either axis — see
    // windows/LockAssemblyOverlay.qml's own identical property for the
    // same reasoning (a fixed pixel distance can't guarantee "fully past
    // any edge" across differently sized monitors).
    readonly property real travel: Math.max(width, height) * 1.1

    // How far each panel's own unique corner (not shared with its
    // diagonal partner's seam) extends past the true screen edge — see
    // windows/LockAssemblyOverlay.qml's own identical property for why
    // (the settle-overshoot stage briefly reveals a sliver of whatever's
    // behind at the true edge otherwise). 2x lockSettleOvershoot is a
    // deliberate safety margin, not the bare minimum.
    readonly property real edgeMargin: Metrics.lockSettleOvershoot * 2

    // Pair 1/2 (the diagonal panels) get a subtly different shade than
    // Theme.background — they're transient (fully covered by pair 3 once
    // resting), so a plain Qt.darker() tint here is fine even though
    // Theme.qml is normally the only source of color: nothing this shade
    // survives onto the resting screen. The bars (pair 3) use
    // Theme.background directly instead, since those ARE what's left
    // showing once assembled.
    readonly property color plateFill: Qt.darker(Theme.background, 1.15)

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    // Each panel's own unique corner (not shared with its diagonal
    // partner's seam) is pushed root.edgeMargin past the true screen
    // edge — see that property's own comment for why. The two seam
    // vertices on every panel below are left exactly as they were.
    Shape {
        id: panelTL
        width: root.width; height: root.height
        x: -root.travel; y: -root.travel
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: -root.edgeMargin; startY: -root.edgeMargin
            PathLine { x: root.width; y: 0 }
            PathLine { x: 0; y: root.height }
            PathLine { x: -root.edgeMargin; y: -root.edgeMargin }
        }
    }

    Shape {
        id: panelBR
        width: root.width; height: root.height
        x: root.travel; y: root.travel
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: root.width; startY: 0
            PathLine { x: root.width + root.edgeMargin; y: root.height + root.edgeMargin }
            PathLine { x: 0; y: root.height }
            PathLine { x: root.width; y: 0 }
        }
    }

    Shape {
        id: panelBL
        width: root.width; height: root.height
        x: -root.travel; y: root.travel
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: -root.edgeMargin; y: root.height + root.edgeMargin }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        id: panelTR
        width: root.width; height: root.height
        x: root.travel; y: -root.travel
        ShapePath {
            fillColor: root.plateFill
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: 0
            PathLine { x: root.width + root.edgeMargin; y: -root.edgeMargin }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // Only the top edge's two corners are pushed up — barTop never
    // translates horizontally, so its left/right edges have no overshoot
    // gap to guard against, only its own top edge does.
    Shape {
        id: barTop
        width: root.width; height: root.height
        y: -root.travel
        ShapePath {
            fillColor: Theme.background
            strokeColor: Theme.foreground
            strokeWidth: 1
            startX: 0; startY: -root.edgeMargin
            PathLine { x: root.width; y: -root.edgeMargin }
            PathLine { x: root.width; y: root.cy }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy }
            PathLine { x: root.cx + root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx - root.halfBoxW; y: root.cy + root.tabDepth }
            PathLine { x: root.cx - root.halfBoxW; y: root.cy }
            PathLine { x: 0; y: root.cy }
            PathLine { x: 0; y: -root.edgeMargin }
        }
    }

    // Same reasoning, mirrored: only the bottom edge's two corners push
    // down.
    Shape {
        id: barBottom
        width: root.width; height: root.height
        y: root.travel
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
            PathLine { x: root.width; y: root.height + root.edgeMargin }
            PathLine { x: 0; y: root.height + root.edgeMargin }
            PathLine { x: 0; y: root.cy }
        }
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: Metrics.spacingLg
        opacity: 0

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
            id: fieldBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: Metrics.moduleHeight
            color: Theme.background
            border.width: 1
            border.color: borderColor

            property color borderColor: Theme.foreground

            function flash() {
                flashFade.stop()
                borderColor = Theme.red
                flashFade.restart()
            }

            ColorAnimation {
                id: flashFade
                target: fieldBox; property: "borderColor"
                to: Theme.foreground
                duration: Metrics.settleDuration * 3
                easing.type: Easing.Linear
            }

            Connections {
                target: root.context
                function onShowFailureChanged() {
                    if (root.context.showFailure)
                        fieldBox.flash()
                }
            }

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: Metrics.spacingSm
                color: Theme.foreground
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeRegular
                echoMode: TextInput.Password
                focus: true
                enabled: root.context && !root.context.unlockInProgress && root.assembled

                onTextChanged: if (root.context) root.context.currentText = text
                Keys.onReturnPressed: if (root.context) root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (root.context.currentText === "" && passwordInput.text !== "")
                            passwordInput.text = ""
                    }
                }

                Connections {
                    target: root
                    function onAssembledChanged() {
                        if (root.assembled)
                            passwordInput.forceActiveFocus()
                    }
                }
            }
        }
    }

    // Entry: overshoot-then-settle per panel (Metrics.lockSettleOvershoot's
    // own comment for the general shape of this motion), pairs staggered
    // sequentially, content fades in only once the bars — the last,
    // topmost layer — have actually locked into place. Not auto-started
    // (running stays false until entranceCheck below decides) — see this
    // file's own top comment for why playing it unconditionally would
    // sometimes mean playing it twice in a row.
    SequentialAnimation {
        id: lockAnimation
        running: false

        ParallelAnimation {
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: panelTL; property: "x"; to: Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelTL; property: "y"; to: Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                }
                ParallelAnimation {
                    NumberAnimation { target: panelTL; property: "x"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelTL; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                }
            }
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: panelBR; property: "x"; to: -Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelBR; property: "y"; to: -Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                }
                ParallelAnimation {
                    NumberAnimation { target: panelBR; property: "x"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelBR; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                }
            }
        }

        ParallelAnimation {
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: panelBL; property: "x"; to: Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelBL; property: "y"; to: -Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                }
                ParallelAnimation {
                    NumberAnimation { target: panelBL; property: "x"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelBL; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                }
            }
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { target: panelTR; property: "x"; to: -Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelTR; property: "y"; to: Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                }
                ParallelAnimation {
                    NumberAnimation { target: panelTR; property: "x"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                    NumberAnimation { target: panelTR; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
                }
            }
        }

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation { target: barTop; property: "y"; to: Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                NumberAnimation { target: barTop; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
            }
            SequentialAnimation {
                NumberAnimation { target: barBottom; property: "y"; to: -Metrics.lockSettleOvershoot; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }
                NumberAnimation { target: barBottom; property: "y"; to: 0; duration: Metrics.lockSettleDuration; easing.type: Easing.Linear }
            }
        }

        NumberAnimation { target: contentColumn; property: "opacity"; to: 1; duration: Metrics.lockStageDuration; easing.type: Easing.Linear }

        onFinished: root.assembled = true
    }

    // Decides whether to play lockAnimation above or skip straight to the
    // resting state — see this file's own top comment. Marker path
    // matches windows/LockAssemblyOverlay.qml's own write exactly (both
    // sides just need to agree on one path, nothing fancier). Checking
    // (and deleting) it via a single test-and-rm shell command, exit code
    // only, rather than a StdioCollector — simpler than parsing output
    // for a plain yes/no.
    property Process entranceCheck: Process {
        command: ["bash", "-c", "test -f \"$XDG_RUNTIME_DIR/syland-lock-skip-entrance\" && rm -f \"$XDG_RUNTIME_DIR/syland-lock-skip-entrance\""]
        onExited: function (exitCode, exitStatus) {
            console.log("[lock] entranceCheck exited code=" + exitCode + " status=" + exitStatus)
            if (exitCode === 0) {
                panelTL.x = 0; panelTL.y = 0
                panelBR.x = 0; panelBR.y = 0
                panelBL.x = 0; panelBL.y = 0
                panelTR.x = 0; panelTR.y = 0
                barTop.y = 0
                barBottom.y = 0
                contentColumn.opacity = 1
                root.assembled = true
            } else {
                lockAnimation.start()
            }
        }
    }

    // Tells windows/LockAssemblyOverlay.qml it's safe to hide now (see
    // its own comment) — fired unconditionally and immediately, whether
    // or not that overlay was actually the thing that triggered this
    // surface in the first place. Harmless when it wasn't (boot,
    // lock_cmd, before_sleep_cmd): nothing is listening for it in that
    // case, since Popups.lockAssemblyOpen was never set true to begin
    // with.
    property Process readyTrigger: Process {
        command: ["qs", "ipc", "call", "lock-assembly", "ready"]
        onStarted: console.log("[lock] readyTrigger started")
        onExited: function (exitCode, exitStatus) {
            console.log("[lock] readyTrigger exited code=" + exitCode + " status=" + exitStatus)
        }
    }

    Component.onCompleted: {
        entranceCheck.running = true
        readyTrigger.running = true
    }
}

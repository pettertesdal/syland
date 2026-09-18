import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

// The "look-alike lock" half of the *locking* handoff — the entrance-side
// counterpart to windows/LockRetreatOverlay.qml (see that file's own
// comment for the unlock-side version of this same trick).
//
// Ordering matters here in a way it doesn't for unlocking, and getting
// it backwards is what broke this the first time: a WlSessionLockSurface
// is guaranteed by the compositor to render above literally everything
// else on screen (the whole point of the ext-session-lock-v1 protocol is
// that nothing can ever cover a lock prompt) — confirmed live, this
// window's own entrance was completely invisible every time an actual
// lock was already active, even though triggering it manually (with no
// real lock competing) worked perfectly. So this has to run *before* the
// real lock exists at all, not after: this window plays its entrance on
// the still-unlocked, still-interactive desktop, and only once it
// finishes does it actually start syland-lock.service — at which point
// the real surface maps already fully resting (home/quickshell-lock/
// LockSurface.qml's own default state, no entrance of its own for this
// path — see that file's own comment) and the swap is invisible.
//
// `qs ipc call lock-assembly trigger` — called directly from the lock
// keybind (home/hypr/keybinds.lua) and hypridle's idle-timeout
// (home/hypr/hypridle.conf), not boot/lock_cmd/before_sleep_cmd, which
// stay on the direct, instant path (see that file's own comment for why:
// this window's entrance means the session stays genuinely unlocked for
// the ~2.4s it plays, an acceptable trade for an already-authenticated
// session choosing to re-lock, not for the windows where minimizing that
// exposure actually matters).
//
// Kept as a genuine separate copy from LockRetreatOverlay.qml rather than
// sharing code between the two — see that file's own comment on why.
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: shown

    // Same pattern as LockRetreatOverlay.qml's own openFlag — a direct
    // binding plus a Connections on root itself, not on the Popups
    // singleton directly (confirmed live not to fire at all).
    property bool openFlag: Popups.lockAssemblyOpen
    property bool shown: false

    // Flipped by LockSurface.qml's own readyTrigger once the real lock
    // surface actually exists — the one signal this window actually
    // waits on before hiding, no guessed-duration timer standing in for
    // it.
    property bool readyFlag: Popups.lockRealReady

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real halfBoxW: Metrics.lockBoxWidth / 2
    readonly property real tabDepth: Metrics.lockBoxHeight / 2
    readonly property real travel: Math.max(width, height) * 1.1
    readonly property color plateFill: Qt.darker(Theme.background, 1.15)

    // How far each panel's own outer corner (the one NOT shared with its
    // diagonal partner's seam) extends past the true screen edge — the
    // settle-overshoot stage briefly translates a panel a few pixels
    // *toward* its resting position, and since that panel's own corner
    // was sitting exactly on the screen edge, that brief overshoot used
    // to reveal a sliver of whatever's behind, right at the boundary.
    // Only the corner unique to each panel gets pushed out (see each
    // panel's own vertex list below) — the two vertices shared with its
    // partner's diagonal seam stay exactly where they are, since those
    // still need to align precisely. 2x lockSettleOvershoot is a
    // deliberate safety margin, not the bare minimum.
    readonly property real edgeMargin: Metrics.lockSettleOvershoot * 2

    // A plain, generous fixed distance — deliberately NOT derived from
    // root.travel — used only for each panel's own *declared* initial
    // x/y (below) and nowhere else. Confirmed live (~/.cache/qs.log)
    // that root.width/height start at a placeholder (100x100) and
    // settle to the real size on an inconsistent timeline (sometimes
    // within 200ms, sometimes not) — deriving the *starting* off-screen
    // position from root.travel meant that whenever it hadn't settled
    // yet, the panels' "off-screen" position wasn't actually off-screen
    // at all (travel=110 is nowhere near off a real 1920-wide monitor),
    // which is what was actually causing the visible static-small-frame
    // bug, not a timing issue to wait out. This number just has to
    // safely exceed any single monitor's own real dimensions — it
    // doesn't need to track anything live. The animation's own
    // overshoot/settle math still uses the real root.travel, re-snapped
    // once startDelay fires below.
    readonly property real farOffscreen: 6000

    Connections {
        target: root
        function onOpenFlagChanged() {
            console.log("[lock-assembly] openFlag=" + root.openFlag + " width=" + root.width + " height=" + root.height + " travel=" + root.travel)
            if (root.openFlag) {
                // Reset here, not in hide() below — confirmed live
                // (binding-loop warning in ~/.cache/qs.log, right at qs
                // startup) that having hide() write
                // Popups.lockRealReady = false from *inside* the handler
                // reacting to readyFlag — which is itself bound straight
                // to that same property — is a genuine self-referential
                // write-back, not just a lint nitpick: QML's own binding-
                // loop detector flagged it, and there's real reason to
                // think that breaks the binding's ability to track
                // further changes for the rest of this process's life —
                // which would exactly explain "works once, stuck on
                // every lock after." Resetting at the start of the next
                // cycle instead, from a completely different signal
                // handler, can't create that same loop.
                Popups.lockRealReady = false
                // Shown immediately again, not deferred — confirmed
                // live that deferring this until after startDelay was
                // actually counterproductive: a layer-shell surface
                // generally only gets told its real configured size
                // *once mapped*, so keeping it hidden through the whole
                // wait meant width/height never got the chance to
                // settle at all (log showed width=100 height=100 still
                // true even after the full delay). The actual fix is
                // farOffscreen's own — the panels' declared starting
                // position no longer depends on root.travel being
                // correct yet, so showing early is safe again: nothing
                // renders anywhere near the visible area regardless of
                // whatever placeholder size the window currently reports.
                root.shown = true
                startDelay.start()
            }
        }
        function onReadyFlagChanged() {
            console.log("[lock-assembly] readyFlag=" + root.readyFlag)
            if (root.readyFlag)
                hide()
        }
    }

    // Marker home/quickshell-lock/LockSurface.qml's own entranceCheck
    // reads (and deletes) at startup, to know this is a swap-triggered
    // lock and skip playing the *same* entrance a second time — path has
    // to match exactly between both sides, nothing fancier than that.
    property Process lockStarter: Process {
        command: ["bash", "-c", "touch \"$XDG_RUNTIME_DIR/syland-lock-skip-entrance\" && systemctl --user start syland-lock.service"]
        onStarted: console.log("[lock-assembly] lockStarter started")
        onExited: function (exitCode, exitStatus) {
            console.log("[lock-assembly] lockStarter exited code=" + exitCode + " status=" + exitStatus)
        }
    }

    // EXPERIMENTAL, not confirmed — trying to close a real but not fully
    // understood bug, seen two related ways so far: pair 1 sometimes
    // shows up already resting instead of sliding in, and (confirmed
    // live) the very first time this window ever plays its entrance in a
    // given qs process, the whole thing can play as a visibly smaller
    // version of every later run. Both point the same direction: this
    // window's own root.width/root.height (and everything derived from
    // them — root.travel, and thus each panel's own starting x/y, which
    // stay live-bound right up until this animation takes them over)
    // might not be settled to their real, final values yet the very
    // first time this window is shown — its Wayland surface still needs
    // a real compositor round-trip (configure/ack/commit) on that first
    // map, regardless of how long the process itself has been running.
    // Confirmed live this doesn't happen on any fixed schedule — one run
    // settled well within 200ms, another was still at the 100x100
    // placeholder *after* the full 200ms wait — so this retries instead
    // of trusting a single fixed guess: if width still looks like the
    // placeholder when this fires, wait another interval and check
    // again, up to a bounded number of attempts (so a genuinely stuck
    // case still eventually proceeds with whatever it has, rather than
    // hang forever).
    Timer {
        id: startDelay
        interval: 200
        running: false
        property int attempts: 0

        onTriggered: {
            // 200, not root.width itself — a real monitor is never this
            // narrow, but the placeholder consistently was (confirmed
            // live, every capture showed exactly 100x100).
            if (root.width < 200 && attempts < 10) {
                attempts += 1
                console.log("[lock-assembly] startDelay: still placeholder-sized (width=" + root.width + "), retry " + attempts)
                restart()
                return
            }
            attempts = 0

            // Explicitly re-snapped to root.travel's *current* value
            // right here, not trusted to still be tracking it live from
            // each panel's own initial `x: -root.farOffscreen`
            // declaration — confirmed live (~/.cache/qs.log) that
            // binding goes stale: individual panels' own x/y properties
            // were staying frozen at a stale value instead of following
            // travel's own later update (captured directly in the log:
            // panelTL.x stuck at -110 even after travel had already
            // become 2112). Every cycle *after* the first happened to
            // look fine purely by accident: hide() below already does
            // this same explicit re-snap when a cycle ends, and by then
            // travel had long since settled, so the next cycle started
            // from an already-correct baked-in value — papering over
            // the same underlying stale-binding issue rather than
            // fixing it.
            panelTL.x = -root.travel; panelTL.y = -root.travel
            panelBR.x = root.travel; panelBR.y = root.travel
            panelBL.x = -root.travel; panelBL.y = root.travel
            panelTR.x = root.travel; panelTR.y = -root.travel
            barTop.y = -root.travel
            barBottom.y = root.travel
            console.log("[lock-assembly] startDelay fired: width=" + root.width + " height=" + root.height + " travel=" + root.travel + " panelTL.x=" + panelTL.x + " panelTL.y=" + panelTL.y)
            assemblyAnimation.start()
        }
    }

    Component.onCompleted: console.log("[lock-assembly] Component.onCompleted: width=" + root.width + " height=" + root.height)

    function hide() {
        console.log("[lock-assembly] hide() called, was shown=" + root.shown)
        root.shown = false
        Popups.lockAssemblyOpen = false
        // lockRealReady is NOT reset here — see onOpenFlagChanged's own
        // comment for why writing it from this handler (reacting to
        // readyFlag, which is bound straight to this same property) was
        // the actual bug.
        contentColumn.opacity = 0
        // farOffscreen, not travel — see that property's own comment;
        // this reset just needs to be safely off-screen for whatever
        // the window's size happens to be at this exact moment, not
        // precisely tuned to it (startDelay's own re-snap, right before
        // the next entrance actually starts, is what establishes the
        // real travel-based position that animation needs).
        panelTL.x = -root.farOffscreen; panelTL.y = -root.farOffscreen
        panelBR.x = root.farOffscreen; panelBR.y = root.farOffscreen
        panelBL.x = -root.farOffscreen; panelBL.y = root.farOffscreen
        panelTR.x = root.farOffscreen; panelTR.y = -root.farOffscreen
        barTop.y = -root.farOffscreen
        barBottom.y = root.farOffscreen
    }

    // All six panels start off-screen (see travel's own comment above) —
    // this window plays the full entrance, unlike LockRetreatOverlay.qml
    // which only ever plays the exit.
    // Each panel's own unique corner (not shared with its diagonal
    // partner's seam) is pushed root.edgeMargin past the true screen
    // edge — see that property's own comment for why. The two seam
    // vertices on every panel below are left exactly as they were.
    Shape {
        id: panelTL
        width: root.width; height: root.height
        x: -root.farOffscreen; y: -root.farOffscreen
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
        x: root.farOffscreen; y: root.farOffscreen
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
        x: -root.farOffscreen; y: root.farOffscreen
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
        x: root.farOffscreen; y: -root.farOffscreen
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
        y: -root.farOffscreen
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
        y: root.farOffscreen
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
        running: root.shown
        repeat: true
        onTriggered: now = new Date()
    }

    // No password field — same reasoning as LockRetreatOverlay.qml's own
    // content: purely cosmetic, the real password field (already live
    // and focused underneath, on the real lock surface, the whole time)
    // is what actually captures typing, even while this window is still
    // visually mid-entrance on top of it.
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
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: Metrics.moduleHeight
            color: Theme.background
            border.width: 1
            border.color: Theme.foreground
        }
    }

    // Same choreography as LockSurface.qml's own lockAnimation:
    // overshoot-then-settle per panel, pairs staggered sequentially,
    // content fades in once the bars — the last, topmost layer — have
    // actually locked into place.
    SequentialAnimation {
        id: assemblyAnimation
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

        // Entrance is done — start the real lock (via lockStarter above)
        // and wait for it to actually confirm it's up (readyFlag,
        // flipped by LockSurface.qml's own readyTrigger) before hiding,
        // rather than hiding immediately. Hiding too early would mean a
        // brief gap where neither this window nor the real lock is
        // showing anything, exposing the still-technically-unlocked
        // desktop underneath for a frame or two — the exact class of gap
        // this whole feature exists to avoid, just on the other end this
        // time.
        onFinished: {
            console.log("[lock-assembly] assemblyAnimation finished, starting real lock")
            lockStarter.running = true
        }
    }
}

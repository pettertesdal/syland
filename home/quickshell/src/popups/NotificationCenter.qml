import QtQuick
import Quickshell
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
// Shaped by shapes/SeamPanelShape.qml: a fixed-width column (not the
// whole screen), flush against the screen's true right edge and true
// bottom edge, with a corner that shares its diagonal exactly with
// windows/RightModule.qml's own bottom-right corner — see that shape's
// own comment for the geometry. The always-visible notification-state
// light (visible even while this panel is closed) lives in its own
// separate window, windows/NotificationLight.qml, not here — this popup
// is a plain AnimatedPopup, mapped only while genuinely open, exactly
// like popups/TodoPanel.qml. That's deliberate, not an oversight: an
// earlier version kept this window permanently mapped (AnimatedPopup's
// own `keepVisible`) so the notch/light could stay visible while
// "closed" — but a persistently-mapped window never gets the "just got
// mapped" transition Hyprland/wlroots need to reliably hand over
// keyboard interactivity (confirmed live: neither toggling
// WlrKeyboardFocus.OnDemand/Exclusive nor a Hyprland submap route worked
// around it cleanly), unlike every other popup in this shell, which get
// that transition for free on every open. Splitting the always-visible
// chrome into its own window let this one go back to the plain,
// TodoPanel-proven pattern below.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    // AnimatedPopup's own PanelWindow base doesn't turn this on (most
    // consumers are click-to-dismiss only) — this panel needs real
    // keyboard input, same as Picker.qml/TodoPanel.qml set it explicitly
    // for themselves. Static true, not tied to openFlag — unlike the
    // permanently-mapped version this used to be, this window gets a
    // real map/unmap cycle every open/close, so there's no reason to
    // toggle this dynamically the way that version needed to.
    focusable: true

    openFlag: Popups.notificationCenterOpen
    onCloseRequested: Popups.notificationCenterOpen = false

    readonly property int panelWidth: 380

    // 0 when fully closed/unmapped, 1 when fully settled open — tracks
    // panel.x directly, so it rides along with openAnim/closeAnim
    // (including the opening overshoot, which briefly pushes this past 1
    // before it settles back) with no separate animation of its own.
    // windows/NotificationLight.qml reads this to slide its own notch tab
    // by the same distance panel.x has moved, so the two windows read as
    // one rigid object in motion instead of a static tab a separate panel
    // happens to slide past.
    //
    // Guarded against root.width < panelWidth, not just a bare ratio —
    // confirmed live (via temporary logging) that root.width sits at a
    // placeholder (100) the entire time this window has never been
    // mapped, since AnimatedPopup's PanelWindow starts `visible: false`
    // and doesn't get a real Wayland configure (real width/height) until
    // first opened (same fact popups/TodoPanel.qml's own beginOpen()
    // comment already documents) — this window being closed the whole
    // time quickshell starts up is the common case, not an edge case.
    // openProgress being read by windows/NotificationLight.qml from
    // outside, before this popup is ever opened once, is what actually
    // exposed it: every other consumer of this same placeholder-width
    // problem elsewhere in this shell only ever deferred an *animation*
    // (beginOpen()/pendingOpen), which doesn't help a plain property read
    // from another window entirely. Without this guard, openProgress
    // latched onto a bogus non-zero value computed from that placeholder
    // and never got asked again until the panel was actually opened once
    // (nothing else in this file re-evaluates it), leaving
    // NotificationLight's own light visibly offset from its correct
    // resting position for the whole time before that first open.
    readonly property real openProgress: root.width >= panelWidth ? (root.width - panel.x) / panelWidth : 0

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
                panel.forceActiveFocus()
            } else {
                // Whatever's in the list right as it closes counts as
                // "seen" — this captures anything that arrived while it
                // was open too, not just what was there at the moment it
                // opened. Lives on the shared service (not a local
                // property here) since windows/NotificationLight.qml
                // needs to read it too.
                NotificationService.seenCount = NotificationService.server.trackedNotifications.values.length
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

        // Keyboard navigation — Up/Down/j/k move the selection, Return
        // dismisses whichever row is selected, Escape closes. Clamped,
        // not wrapping (same choice Picker.qml/TodoPanel.qml already
        // made). Kept in sync with the live list via the Connections
        // below, since dismissing (from here or the mouse) or a new
        // notification arriving both change the list's length out from
        // under whatever was selected.
        property int currentIndex: 0
        // Keeps the selection scrolled into view without touching
        // ListView.currentIndex itself (see notificationList's own
        // comment for why that binding was an earlier focus bug).
        // ListView.Contain: scrolls the minimum amount needed to bring
        // the row fully into view, not centering it every time.
        onCurrentIndexChanged: notificationList.positionViewAtIndex(currentIndex, ListView.Contain)

        function moveSelection(delta) {
            var count = NotificationService.server.trackedNotifications.values.length
            if (count === 0) return
            currentIndex = Math.min(Math.max(currentIndex + delta, 0), count - 1)
        }

        function dismissSelected() {
            var tracked = NotificationService.server.trackedNotifications.values
            if (currentIndex >= 0 && currentIndex < tracked.length)
                tracked[currentIndex].dismiss()
            // dismiss() removes a delegate from the ListView, which was
            // observed live to sometimes leave the window with no
            // actively-focused item at all afterward (nothing further to
            // absorb the keyboard until clicking back in or toggling the
            // panel closed/open again) — reasserting focus explicitly
            // covers this regardless of the exact Qt Quick focus-chain
            // mechanics behind it.
            panel.forceActiveFocus()
        }

        Connections {
            target: NotificationService.server.trackedNotifications
            function onValuesChanged() {
                var count = NotificationService.server.trackedNotifications.values.length
                if (panel.currentIndex >= count)
                    panel.currentIndex = Math.max(0, count - 1)
            }
        }

        Keys.onUpPressed: panel.moveSelection(-1)
        Keys.onDownPressed: panel.moveSelection(1)
        Keys.onReturnPressed: panel.dismissSelected()
        Keys.onEscapePressed: Popups.notificationCenterOpen = false

        // j/k alongside the arrow keys, not instead of — a generic
        // Keys.onPressed rather than dedicated Keys.onXPressed signals,
        // since QML doesn't have those for plain letter keys. Same
        // pattern TodoPanel.qml uses for its own Tab handling.
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_J) {
                panel.moveSelection(1)
                event.accepted = true
            } else if (event.key === Qt.Key_K) {
                panel.moveSelection(-1)
                event.accepted = true
            }
        }

        readonly property int restX: parent.width - width
        readonly property int hiddenX: parent.width

        // Driven entirely by openAnim/closeAnim below, not a live binding
        // + Behavior — see popups/TodoPanel.qml's own comment on the
        // identical `x: hiddenX` line for why (Behavior's implicit
        // target/property inference doesn't reliably reach nested
        // NumberAnimations inside a SequentialAnimation).
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
            // almost its whole width (see SeamPanelShape.qml) — content
            // has to clear that, not just y=0, or it'd render in the
            // transparent area above the visible fill.
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
                    visible: NotificationService.server.trackedNotifications.values.length > 0
                    text: "clear all"
                    color: Theme.accent
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall

                    TapHandler {
                        onTapped: {
                            var tracked = NotificationService.server.trackedNotifications.values
                            for (var i = tracked.length - 1; i >= 0; i--)
                                tracked[i].dismiss()
                        }
                    }
                }
            }

            Text {
                visible: NotificationService.server.trackedNotifications.values.length === 0
                text: "No notifications"
                color: Theme.foreground
                opacity: 0.6
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeRegular
            }
        }

        ListView {
            id: notificationList
            anchors.top: header.bottom
            anchors.topMargin: Metrics.spacingSm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.spacingMd
            clip: true
            spacing: Metrics.spacingSm
            model: NotificationService.server.trackedNotifications
            // Deliberately NOT `currentIndex: panel.currentIndex` — that
            // was the actual cause of an earlier focus bug (confirmed
            // live via logging): setting ListView.currentIndex engages
            // the view's own built-in keyboard-navigation/focus
            // machinery, which expects the ListView itself to hold
            // keyboard focus and drive its own arrow-key handling.
            // That's a different model than what's built here (panel
            // holds focus, handles keys itself, this is just a plain
            // index) — the mismatch was stealing active focus away from
            // panel the moment the index changed, including on the very
            // first selection. Auto-scroll to keep the selection visible
            // is done manually above instead (panel.onCurrentIndexChanged),
            // which doesn't touch focus at all.

            // A wrapping Item rather than using NotificationCard directly
            // as the delegate — needed for the selection-highlight
            // Rectangle, without touching NotificationCard.qml itself
            // (shared with popups/NotificationToast.qml, which has no
            // concept of "selected").
            delegate: Item {
                id: notifRow
                // required property, not a bare `modelData` reference —
                // this file sits nested inside shell.qml's per-screen
                // `Scope { required property var modelData }` (the
                // QuickshellScreenInfo from Variants), which shadows a
                // ListView's own implicit modelData if the delegate
                // doesn't explicitly re-declare it. Same pattern
                // windows/LeftModule.qml and popups/NotificationToast.qml
                // already use for exactly this reason.
                required property var modelData
                // Once a delegate declares any required property, Qt
                // Quick stops implicitly injecting the other model roles
                // (like index) as ordinary context properties — has to
                // be declared required too, or reading it is a runtime
                // error (confirmed the hard way building TodoPanel.qml).
                required property int index

                width: ListView.view.width
                height: card.implicitHeight

                readonly property bool selected: notifRow.index === panel.currentIndex

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: notifRow.modelData
                    // The panel itself already has a border — individually
                    // boxing every row would just nest rectangles. Rows are
                    // separated by the ListView's own spacing instead.
                    bordered: false
                }

                // Declared AFTER (rendered on top of) the card, not
                // before it — NotificationCard's own root is an OPAQUE
                // Theme.background Rectangle, so a highlight declared
                // earlier in sibling order was being completely covered
                // by it, invisible regardless of its own color/opacity.
                // Confirmed live: this exact ordering mistake is why
                // nothing showed up at all.
                Rectangle {
                    anchors.fill: parent
                    visible: notifRow.selected
                    color: Theme.accent
                    opacity: 0.15
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    visible: notifRow.selected
                    color: Theme.accent
                }
            }
        }
    }
}

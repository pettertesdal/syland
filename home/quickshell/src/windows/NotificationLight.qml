import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

// Always-visible notification-state indicator, split out from
// popups/NotificationCenter.qml (see that file's own top-of-file
// comment) so the popup itself can go back to a plain, normally-
// hidden-until-open AnimatedPopup — exactly like popups/TodoPanel.qml —
// and get the reliable real Wayland keyboard focus that requires (a
// real unmap/map cycle on every open/close), instead of staying
// permanently mapped just to keep this notch visible.
//
// Geometry ported unchanged from shapes/SeamPanelShape.qml's own former
// notch math (see its git history) — that combined shape+light Canvas
// was confirmed working/visually correct against the hand-drawn mockup
// before this split, so tabDepth/lightTopY/lightBottomY below reproduce
// those exact same points, just as their own small closed polygon
// instead of a few extra lineTo()s tacked onto a much larger,
// mostly-off-screen panel outline.
//
// Slides in lockstep with notificationCenter's own panel.x (see
// `shift` below) — in the original single-shape version, the notch was
// rigidly part of the same Canvas as the whole panel, so it moved by
// exactly the panel's own x delta for free. Split into a separate
// window, that has to be done explicitly: notificationCenter exposes
// openProgress (0 closed, 1 open, tracking panel.x directly, including
// its opening overshoot) and this window reads it to shift the tab by
// the same distance, so the two read as one rigid object rather than a
// static tab a separate panel slides past.
PanelWindow {
    id: root

    // notificationCenter — set from shell.qml, the same per-screen
    // popups/NotificationCenter.qml instance this window's light belongs
    // to (same pattern popups/BluetoothPanel.qml's own `rightModule`
    // property uses to reach windows/RightModule.qml).
    property var notificationCenter: null

    anchors { top: true; right: true; bottom: true }
    // Wide enough for the tab to slide the panel's own full width to the
    // left without running off this window's own surface bounds — a
    // Wayland surface clips anything positioned outside its own [0,width]
    // extent, unlike an ordinary overflowing Qt Quick Item, so this has
    // to actually be sized for the tab's full travel range, not just its
    // resting width. Mirrors the old combined Canvas's own
    // `width: parent.width + 10` for the identical reason.
    implicitWidth: tabDepth + panelWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    // Only the small visible tab should ever intercept a click — without
    // this, a fully transparent but still-mapped window captures pointer
    // input across its *entire* extent (here, a wide strip running the
    // full height of the screen), same class of bug
    // components/HangingModule.qml's own mask already exists to avoid.
    // Bound to tab's own live bounds, so this keeps tracking correctly as
    // tab.x slides.
    mask: Region { item: tab }

    readonly property int tabDepth: 10
    // Mirrors popups/NotificationCenter.qml's own `panelWidth`/
    // `height: parent.height - panelWidth` — the light's Y position was
    // always computed against that shortened height (a gap left at the
    // screen's true bottom, sized to the panel's own width), not the raw
    // screen height, and has to keep using the same reference here or
    // the two would drift apart if panelWidth or the screen height ever
    // changes.
    readonly property int panelWidth: 380
    readonly property real refHeight: height - panelWidth

    readonly property real lightBottomY: refHeight / 3
    readonly property real lightTopY: lightBottomY - 2 * Metrics.chamferSize - Metrics.moduleMargin
    readonly property real tabHeight: lightBottomY - lightTopY

    // How far left of its resting position the tab currently sits — 0
    // while notificationCenter is closed, growing to panelWidth once
    // it's fully open (and briefly past that during the opening
    // overshoot, riding the bounce along with it).
    readonly property real shift: (notificationCenter ? notificationCenter.openProgress : 0) * panelWidth

    Canvas {
        id: tab
        width: root.tabDepth
        height: root.tabHeight
        y: root.lightTopY
        // Resting flush against the true right edge, sliding left by
        // `shift` as notificationCenter opens.
        x: root.width - width - root.shift

        property color fillColor: Theme.background
        property color strokeColor: Theme.foreground

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onStrokeColorChanged: requestPaint()

        // Canvas only auto-repaints on its own property changes (above)
        // — Metrics.chamferSize/moduleMargin are read directly inside
        // onPaint below, not through a dedicated property, so a change
        // to either (e.g. Metrics settling to its real values shortly
        // after quickshell starts, rather than whatever it initializes
        // to on the very first tick) wouldn't otherwise trigger a
        // repaint at all — matches shapes/SeamPanelShape.qml's own
        // identical Connections block, ported from there along with the
        // rest of this shape's geometry.
        Connections {
            target: Metrics
            function onChamferSizeChanged() { tab.requestPaint() }
            function onModuleMarginChanged() { tab.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var p = width
            var c = Metrics.chamferSize
            var m = Metrics.moduleMargin

            ctx.beginPath()
            ctx.moveTo(p, 0)          // top-right corner, flush with the panel's own right edge
            ctx.lineTo(0, c)          // chamfer down to the tip
            ctx.lineTo(0, c + m)      // straight down the tip
            ctx.lineTo(p, height)     // chamfer back out to the bottom-right corner
            ctx.closePath()

            ctx.fillStyle = tab.fillColor
            ctx.fill()

            ctx.lineWidth = 1
            ctx.strokeStyle = tab.strokeColor
            ctx.stroke()
        }
    }

    // Green once you've seen everything currently there
    // (services/NotificationService.qml's own seenCount, set when
    // NotificationCenter closes), yellow when something new has arrived
    // since. Not tied to dismissal — clearing/dismissing already-seen
    // notifications stays green, since nothing new showed up.
    Rectangle {
        width: 8
        height: 8
        radius: width / 2
        x: tab.x + (tab.width - width) / 2
        y: root.lightTopY + (root.tabHeight - height) / 2
        color: NotificationService.server.trackedNotifications.values.length > NotificationService.seenCount
            ? Theme.yellow : Theme.green
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../shapes"

// Shared mechanics for the three top-of-screen modules (windows/LeftModule.qml,
// CenterModule.qml, RightModule.qml) — same relationship AnimatedPopup has to
// its consumers: this owns the PanelWindow/shape/padding/positioning,
// consumers supply content and set `boxWidth`/`align` (left/center/right).
//
// The window itself spans the full screen width (anchored top+left+right,
// fully transparent) so horizontal centering can be a plain declarative `x`
// binding — PanelWindow anchors are edge-based with no direct "center on
// screen" option, and juggling three different per-module anchor strategies
// (corner vs. centered) would be more inconsistent than one window wide
// enough to position a box anywhere inside it.
//
// Decorative, not exclusive-zone: unlike the old full-width TopBar, three
// separate boxes with gaps between them can't form one wlr-layer-shell
// exclusive zone the way a single full-width bar could, so this doesn't
// reserve screen space — windows can render underneath.
//
// Optional grow capability, opt-in via `grown`/`grownWidth`/`grownHeight`
// (all no-ops by default — LeftModule/CenterModule never touch them, so
// they're unaffected). windows/RightModule.qml uses this to expand into
// the bluetooth panel *in place*, as the same window growing and swapping
// its own content, rather than a second window trying to visually
// impersonate this one and then fighting over which renders on top —
// z-order between two separate wlr-layer-shell surfaces isn't something
// that can be reliably choreographed to jump on cue, so there's only ever
// one window here to begin with.
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true }
    // Always sized to the largest state this module will ever need
    // (grownHeight — for LeftModule/CenterModule, which never grow, this
    // is just Metrics.moduleHeight, identical to before). The window's
    // real size never changes after creation: no resize events, so
    // nothing for a Wayland surface resize to visually glitch on — an
    // earlier version resized the real window between small/grown states
    // and got a "trailing white box" during the transition, apparently
    // the surface's own buffer not clearing properly for the
    // newly-exposed area right after a real resize. `box` below is what
    // actually animates, a cheap scene-graph-native Item resize with
    // nothing Wayland-level involved. `mask` keeps real input scoped to
    // box's own current bounds, so a permanently-tall transparent window
    // doesn't swallow clicks meant for whatever's underneath while this
    // module is small/idle.
    implicitHeight: grownHeight + maxYShift
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    // Ordinary hanging modules sit on the same layer as Border/TopBar-
    // equivalents; grown, or riding along with an Overlay-layer popup
    // (maxYShift > 0 — windows/CenterModule.qml/RightModule.qml wire this
    // once, to a constant, whenever they're configured to track one),
    // this needs to draw above normal windows the same way
    // AnimatedPopup's own popups do — otherwise, once yShift actually
    // carries the box down into the same screen region the popup's own
    // body occupies, the box renders *underneath* that popup's opaque
    // fill instead of on top of it. Confirmed live: this is exactly what
    // "I don't see RightModule once BluetoothPanel is open" was.
    WlrLayershell.layer: (grown || maxYShift > 0) ? WlrLayer.Overlay : WlrLayer.Top
    mask: Region { item: box }

    property string align: "left" // "left" | "center" | "right"
    property int boxWidth: 100
    default property alias content: contentItem.data

    // Exposed so a sibling window can position itself relative to this
    // module's actual on-screen box — windows/MusicModule.qml uses this
    // (via a `centerModule` reference, same pattern
    // popups/BluetoothPanel.qml's own `rightModule` property uses) to
    // sit flush against windows/CenterModule.qml's clock, since that's a
    // separate wlr-layer-shell window with its own independent geometry,
    // not something a plain anchor/alignment on this window alone could
    // reach.
    readonly property alias boxX: box.x

    property bool grown: false
    property int grownWidth: boxWidth
    property int grownHeight: Metrics.moduleHeight

    // Opt-in vertical offset for box — no-op (0) by default, so
    // LeftModule/RightModule are unaffected. windows/CenterModule.qml
    // uses this to ride down with popups/Picker.qml's own opening
    // animation (that popup exposes an openProgress the same way
    // popups/NotificationCenter.qml does for
    // windows/NotificationLight.qml — same "always-visible element
    // tracks a separate popup's motion" trick). maxYShift has to be
    // reserved up front in implicitHeight, same reasoning grownHeight
    // already documents above: box moving outside this window's own
    // mapped surface bounds would just get clipped by Wayland, not
    // resized into.
    property real yShift: 0
    property int maxYShift: 0

    Item {
        id: box
        width: root.grown ? root.grownWidth : root.boxWidth
        height: root.grown ? root.grownHeight : Metrics.moduleHeight
        Behavior on width { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
        Behavior on height { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
        y: root.yShift
        x: {
            if (root.align === "left") return Metrics.moduleMargin
            if (root.align === "right") return parent.width - width - Metrics.moduleMargin
            return (parent.width - width) / 2
        }

        HangingBoxShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: Theme.foreground
            chamfer: Metrics.chamferSize
        }

        Item {
            id: contentItem
            anchors.fill: parent
            anchors.margins: Metrics.spacingMd
            // Extra clearance at the bottom so content doesn't sit under
            // the diagonal cut corners.
            anchors.bottomMargin: Metrics.chamferSize
            // Content sized for the grown state would otherwise render
            // past the shape's own edges mid-animation, before the box
            // has grown enough to actually contain it. Clipping here
            // instead of on `box` itself matters: box's own edge sits
            // exactly on HangingBoxShape's 1px stroke (centered on the
            // boundary, so half of it is technically outside box's
            // bounds) — clipping at the box level cut that half away,
            // which is why the left/top edges of every hanging module
            // went missing once this existed.
            clip: true
        }
    }
}

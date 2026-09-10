import QtQuick
import Quickshell
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
PanelWindow {
    id: root

    anchors { top: true; left: true; right: true }
    implicitHeight: Metrics.moduleHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    property string align: "left" // "left" | "center" | "right"
    property int boxWidth: 100
    default property alias content: contentItem.data

    Item {
        id: box
        width: root.boxWidth
        height: Metrics.moduleHeight
        y: 0
        x: {
            if (root.align === "left") return Metrics.spacingMd
            if (root.align === "right") return parent.width - width - Metrics.spacingMd
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
        }
    }
}

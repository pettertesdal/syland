import QtQuick
import QtQuick.Shapes

// popups/BluetoothPanel.qml's own outline — Shape/ShapePath, not a
// Canvas like SeamPanelShape: this shape's *height* animates every
// frame during open/close, and Canvas needs an explicit requestPaint()
// per resize that can't keep up with a smooth animation — the exact
// "trailing unpainted strip" bug shapes/HangingBoxShape.qml's own header
// comment already documents for this same reason. Shape is scene-graph
// native, so it can't lag the same way.
//
// A narrow top section (topWidth wide, topInset from the right edge,
// square corners) meant to exactly coincide with
// windows/RightModule.qml's own resting silhouette — same width, same
// right-edge inset (Metrics.moduleMargin) — so at minimum height
// (topHeight), this shape degenerates to plain RightModule's own
// rectangle, nothing new drawn; growing height beyond topHeight reveals
// the full-width body below, with chamfered bottom corners (same
// Metrics.chamferSize cut vocabulary as HangingBoxShape/SeamPanelShape).
//
// VERIFY: reconstructed from a hand-drawn reference image plus a Q&A
// description of what it shows, not exact measurements — confirm the
// step proportions read right once built. Getting a sketch's exact
// pixel geometry right from a text description alone isn't realistic;
// this is a best-effort starting point for a live visual check, not a
// claim of pixel-perfect accuracy.
Shape {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"
    property int chamfer: 10
    property int topWidth: width
    property int topInset: 0
    property int topHeight: 32

    readonly property int _c: Math.max(0, Math.min(chamfer, width / 2, Math.max(0, height - topHeight)))

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        strokeWidth: 1
        startX: root.width - root.topInset - root.topWidth
        startY: 0

        // Top-right of the narrow section — right-inset by topInset,
        // matching RightModule's own moduleMargin gap from the true
        // screen edge, not flush against it.
        PathLine { x: root.width - root.topInset; y: 0 }
        PathLine { x: root.width - root.topInset; y: root.topHeight }
        // Step right, out to the wide body's own (flush) right edge.
        PathLine { x: root.width; y: root.topHeight }
        PathLine { x: root.width; y: root.height - root._c }
        PathLine { x: root.width - root._c; y: root.height }
        PathLine { x: root._c; y: root.height }
        PathLine { x: 0; y: root.height - root._c }
        PathLine { x: 0; y: root.topHeight }
        // Step right, back in to the narrow section's own left edge.
        PathLine { x: root.width - root.topInset - root.topWidth; y: root.topHeight }
        PathLine { x: root.width - root.topInset - root.topWidth; y: 0 }
    }
}

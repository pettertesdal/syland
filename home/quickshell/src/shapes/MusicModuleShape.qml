import QtQuick
import QtQuick.Shapes

// The music-module outline flanking windows/CenterModule.qml's clock.
// Six points, walked as: outer top corner -> straight diagonal down to
// the bottom (no vertical segment on the outer side, unlike an ordinary
// corner chamfer) -> along the bottom edge -> a short diagonal poking
// out past the inner-bottom corner -> back inward at that same height
// -> straight up to the top edge -> close back along the top. The last
// four points are the "overhang": the main body's inner edge sits at
// tailDepth in from the inner edge for most of the height, but a
// tailHeight-tall foot near the bottom pokes out an extra tailExtend
// past that, so the upper body reads as hanging over the lower foot.
// Geometry worked out point-by-point against the hand-drawn mockups
// (Syland-music_left_with_cassett-widget-form.png /
// Syland-music_right-widget-form.png), not derived from a formula.
Shape {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"
    // "left": outer (no-vertical-segment) edge on the left, tail/
    // overhang on the right (toward the clock). "right": mirrored.
    property string align: "left"
    // windows/StatsModule.qml's own use: mirrors every point across the
    // shape's own vertical midline (y -> h - y), so the flat edge (the
    // one facing the screen edge this shape's window is anchored to)
    // swaps from top to bottom and the tail swaps correspondingly from
    // "pokes out near the bottom, toward whatever sits below" to "pokes
    // out near the top, toward whatever sits above" — same relationship
    // to the neighboring gap-filling panel either way, just mirrored for
    // a bottom-anchored window instead of a top-anchored one.
    property bool flipV: false

    property int outerInset: 15 // how far the outer diagonal's bottom point lands, in from the outer edge
    property int tailDepth: 8   // main body's inner edge, in from the inner edge
    property int tailExtend: 13  // how far the tail's tip pokes out past tailDepth
    property int tailHeight: 6  // how tall the tail/overhang region is, up from the bottom

    readonly property var _pts: {
        var w = width, h = height
        var bodyRight = w - tailDepth
        var tailTipX = bodyRight + tailExtend
        var tailTopY = h - tailHeight
        var pts = [
            { x: 0, y: 0 },
            { x: outerInset, y: h },
            { x: bodyRight, y: h },
            { x: tailTipX, y: tailTopY },
            { x: bodyRight, y: tailTopY },
            { x: bodyRight, y: 0 }
        ]
        if (flipV)
            pts = pts.map(function (p) { return { x: p.x, y: h - p.y } })
        if (align === "right")
            pts = pts.map(function (p) { return { x: w - p.x, y: p.y } })
        return pts
    }

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        strokeWidth: 1
        startX: root._pts[0].x
        startY: root._pts[0].y

        PathLine { x: root._pts[1].x; y: root._pts[1].y }
        PathLine { x: root._pts[2].x; y: root._pts[2].y }
        PathLine { x: root._pts[3].x; y: root._pts[3].y }
        PathLine { x: root._pts[4].x; y: root._pts[4].y }
        PathLine { x: root._pts[5].x; y: root._pts[5].y }
        // See shapes/PickerPanelShape.qml's identical comment: ShapePath
        // auto-closes for fill but not for stroke — without this, the
        // top edge (5 -> 0) never got a visible stroke at all.
        PathLine { x: root._pts[0].x; y: root._pts[0].y }
    }
}

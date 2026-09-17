import QtQuick
import QtQuick.Shapes
import "../"

// popups/Picker.qml's own outline. Each ear is a plain square-cornered
// cap flush with the true top corners — not the tail's inverse (a
// concave notch, tried and rejected), but literally the block sitting
// *above* where shapes/MusicModuleShape.qml's own tail pokes out: same
// width as that poke (tailExtend), right angles, no diagonal at all.
// Steps in to the main body's own edge at outerEdgeDrop, which still
// equals Metrics.moduleContentHeight — the same height
// windows/MusicModule.qml's own box uses, so the cap's own bottom lines
// up with where that module actually sits, even though the cap's shape
// itself doesn't trace the tail directly anymore.
Shape {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"

    property int outerEdgeDrop: Metrics.moduleContentHeight
    // How far each ear extends past the main body's own edge — the
    // tail's own protrusion length (shapes/MusicModuleShape.qml's
    // tailExtend), reused rather than re-tuned separately.
    property int outerEdgeWidth: 13
    // popups/ThemeSwitcher.qml's own use: mirrors every point across the
    // shape's own vertical midline (y -> h - y), same as
    // shapes/MusicModuleShape.qml's own flipV — the ears move from the
    // top (touching windows/MusicModule.qml, this shape's original use
    // in popups/Picker.qml) to the bottom (touching
    // windows/StatsModule.qml instead), and the main body correspondingly
    // grows upward from there instead of downward.
    property bool flipV: false

    readonly property var _pts: {
        var w = width, h = height
        var ew = outerEdgeWidth, ed = outerEdgeDrop -6
        var corner = 5
        var pts = [
            { x: 0, y: 0 },
            { x: w, y: 0 },
            { x: w, y: ed },
            { x: w - ew, y: ed },
            { x: w - ew, y: h - corner },
            { x: w - ew - corner, y: h },
            { x: ew + corner, y: h },
            { x: ew, y: h - corner },
            { x: ew, y: ed },
            { x: 0, y: ed }
        ]
        if (flipV)
            pts = pts.map(function (p) { return { x: p.x, y: h - p.y } })
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
        PathLine { x: root._pts[6].x; y: root._pts[6].y }
        PathLine { x: root._pts[7].x; y: root._pts[7].y }
        PathLine { x: root._pts[8].x; y: root._pts[8].y }
        PathLine { x: root._pts[9].x; y: root._pts[9].y }
        // ShapePath auto-closes for fill purposes but does NOT stroke the
        // closing edge back to startX/startY on its own — without this
        // explicit segment back to _pts[0], the left ear's own left edge
        // (the 9->0 segment) never got a visible stroke at all, which is
        // what actually read as "missing top border on the left ear."
        PathLine { x: root._pts[0].x; y: root._pts[0].y }
    }
}

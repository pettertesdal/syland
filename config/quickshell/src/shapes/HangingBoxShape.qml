import QtQuick
import QtQuick.Shapes

// The "hanging tag" outline every HangingModule uses: flush top edge (the
// two top corners are square, as if pinned to the screen's top edge), and
// the two bottom corners cut diagonally inward — a hexagon, not a
// rectangle. Built with Shape/ShapePath rather than Canvas: this shape
// gets resized every frame while windows/RightModule.qml grows into the
// bluetooth panel, and Canvas needs an explicit requestPaint() per
// resize, which can't keep up with a smooth per-frame animation — the
// visible symptom was a trailing unpainted strip (rendering as a white
// box) lagging behind the actual growing bounds. Shape is scene-graph
// native: its geometry just re-evaluates from the width/height bindings
// below with no manual repaint step, so it can't lag the same way.
Shape {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"
    property int chamfer: 10

    readonly property int _c: Math.max(0, Math.min(chamfer, width / 2, height))

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeColor
        strokeWidth: 1
        startX: 0
        startY: 0

        PathLine { x: root.width; y: 0 }
        PathLine { x: root.width; y: root.height - root._c }
        PathLine { x: root.width - root._c; y: root.height }
        PathLine { x: root._c; y: root.height }
        PathLine { x: 0; y: root.height - root._c }
        PathLine { x: 0; y: 0 }
    }
}

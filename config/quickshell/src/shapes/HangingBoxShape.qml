import QtQuick

// The "hanging tag" outline every HangingModule uses: flush top edge (the
// two top corners are square, as if pinned to the screen's top edge), and
// the two bottom corners cut diagonally inward — a hexagon, not a
// rectangle. Same Canvas/requestPaint-on-change convention the old
// windows/Border.qml and the now-deleted PopupShape.qml used, but with
// straight lineTo() cuts instead of arcTo()/quadraticCurveTo() curves —
// a different technique in the same spirit, fitting the terminal-minimal
// direction (straight lines) rather than reviving the melt-into-border
// curve that direction moved away from.
Canvas {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"
    property int chamfer: 10

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onChamferChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var w = width
        var h = height
        var c = Math.min(root.chamfer, w / 2, h)

        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(w, 0)
        ctx.lineTo(w, h - c)
        ctx.lineTo(w - c, h)
        ctx.lineTo(c, h)
        ctx.lineTo(0, h - c)
        ctx.closePath()

        ctx.fillStyle = root.fillColor
        ctx.fill()

        ctx.lineWidth = 1
        ctx.strokeStyle = root.strokeColor
        ctx.stroke()
    }
}

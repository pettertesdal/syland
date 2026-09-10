import QtQuick
import "../"

// The notification panel's outline: flush against the screen's true left
// AND right edges (its own top-left, bottom-left, bottom-right corners
// stay square, same "physical edges stay flush" rule windows/Border.qml
// follows) — except one notch cut into the top-right area, sized and
// positioned to share its diagonal exactly with windows/RightModule.qml's
// own bottom-right chamfer. Both shapes are built from the same
// Metrics.moduleHeight/moduleMargin/chamferSize constants, so the two
// diagonals land on the identical line rather than merely a close one.
//
// Confirmed against a mockup before building: the panel's top edge runs
// flat from the true left edge out to the seam, diagonals up to meet
// RightModule's own corner point, then continues flat for the same
// Metrics.moduleMargin distance out to the screen's true right edge — it
// does NOT stop at RightModule's own (narrower) right edge.
Canvas {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onStrokeColorChanged: requestPaint()

    Connections {
        target: Metrics
        function onModuleHeightChanged() { root.requestPaint() }
        function onModuleMarginChanged() { root.requestPaint() }
        function onChamferSizeChanged() { root.requestPaint() }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var w = width
        var h = height
        var mh = Metrics.moduleHeight
        var m = Metrics.moduleMargin
        var c = Metrics.chamferSize

        var seamRightX = w - m       // RightModule's own right edge x
        var seamLeftX = seamRightX - c // RightModule's bottom-right chamfer's other end
        var seamTopY = mh - c
        var seamBottomY = mh

        ctx.beginPath()
        ctx.moveTo(0, seamBottomY)             // top-left, flush against the true left edge
        ctx.lineTo(seamLeftX, seamBottomY)      // flat top, up to the seam
        ctx.lineTo(seamRightX, seamTopY)        // the shared diagonal with RightModule
        ctx.lineTo(w, seamTopY)                 // flat again, out to the true right edge
        ctx.lineTo(w, h)                        // down the true right edge
        ctx.lineTo(0, h)                        // along the true bottom edge
        ctx.closePath()

        ctx.fillStyle = root.fillColor
        ctx.fill()

        ctx.lineWidth = 1
        ctx.strokeStyle = root.strokeColor
        ctx.stroke()
    }
}

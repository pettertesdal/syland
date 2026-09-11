import QtQuick
import "../"

// A "growing" panel's outline — originally built for popups/NotificationCenter.qml,
// now shared with popups/BluetoothPanel.qml too, since the shape itself has
// nothing notification-specific about it: it's just any panel that reads as
// windows/RightModule.qml expanding downward. The panel doesn't sit flush
// against any true screen edge except the middle stretch of its right side
// (both its width and its gap above the screen's true bottom edge keep
// every other edge floating), so every corner gets the same
// Metrics.chamferSize cut — all four diagonals the same length:
//   - top-left, bottom-left, bottom-right: an ordinary chamferSize corner
//     cut, nothing else nearby to gesture at.
//   - top-right: the one special case — sized/positioned to share its
//     diagonal exactly with RightModule's own bottom-right chamfer (same
//     chamferSize, just placed precisely rather than in a plain corner),
//     then flat out to the true right edge for Metrics.moduleMargin —
//     confirmed against a mockup before building.
// Built from the same Metrics.moduleHeight/moduleMargin/chamferSize
// constants RightModule uses, so the top-right diagonal lands on the
// identical line rather than merely a close one, for any consumer.
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
        ctx.moveTo(0, seamBottomY + c)          // top-left chamfer start (down the left edge)
        ctx.lineTo(c, seamBottomY)              // cut the top-left corner
        ctx.lineTo(seamLeftX, seamBottomY)       // flat top, up to the seam
        ctx.lineTo(seamRightX, seamTopY)        // the shared diagonal with RightModule
        ctx.lineTo(w, seamTopY)                 // flat again, out to the true right edge
        ctx.lineTo(w, h - c)                    // down the right edge
        ctx.lineTo(w - c, h)                    // cut the bottom-right corner
        ctx.lineTo(c, h)                        // flat bottom edge
        ctx.lineTo(0, h - c)                    // cut the bottom-left corner
        ctx.closePath()

        ctx.fillStyle = root.fillColor
        ctx.fill()

        ctx.lineWidth = 1
        ctx.strokeStyle = root.strokeColor
        ctx.stroke()
    }
}

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
// Plain rectangle top (flush corners, full width) with chamfered bottom
// corners — same Metrics.chamferSize cut vocabulary as
// HangingBoxShape/SeamPanelShape. Used to have a narrow top section
// matching windows/RightModule.qml's own resting silhouette (so the
// panel visually *was* RightModule at minimum height), but that's gone
// now that RightModule rides down with this panel as it grows (its own
// yShift/maxYShift, same mechanism windows/CenterModule.qml uses for
// popups/Picker.qml) instead of needing to be impersonated while closed.
//
// Below notificationLightY, the right edge steps in by notificationLightX
// instead of running flush to the true screen edge — windows/NotificationLight.qml's
// own tab lives on that same right edge, further down the screen, and
// without this the panel's own grown body would run straight through it.
// The step itself is a diagonal chamfer (chamfer-sized), matching
// NotificationLight's own tab shape rather than a plain square corner —
// one diagonal in, then stays inset for the rest of the panel's height
// (nothing below the light needs the same clearance, so no matching
// diagonal back out).
Shape {
    id: root

    property color fillColor: "black"
    property color strokeColor: "white"
    property int chamfer: 10
    // Distance from the true right screen edge to windows/NotificationLight.qml's
    // own tab — its width plus however far left it's currently shifted
    // (popups/BluetoothPanel.qml computes this as tabDepth + shift) — and
    // the Y where that tab's own top sits. Defaults are just a
    // standalone-preview fallback (see this repo's own CLAUDE.md on
    // testing a single writeShellApplication/shape in isolation); real
    // values always come from the actual NotificationLight instance.
    property int notificationLightX: 10
    property int notificationLightY: 200

    readonly property int _c: Math.max(0, Math.min(chamfer, width / 2, height))
    // Clamped so the diagonal's own two endpoints ((_lightY - chamfer)
    // and _lightY) both stay within [0, height - _c] — the right edge's
    // own valid vertical range — keeping the shape sane even mid-
    // animation, while height is still growing and hasn't reached the
    // light's real Y yet.
    readonly property real _lightY: Math.max(chamfer, Math.min(notificationLightY, height - _c))

    readonly property var _pts: [
        { x: 0, y: 0 },                                           // 0: start — top-left
        { x: width, y: 0 },                                       // 1: top-right, flush
        { x: width, y: _lightY },                       // 2: down the flush right edge, to just above the light
        { x: width - notificationLightX, y: _lightY + chamfer },            // 3: diagonal step in, clearing the light
        { x: width - notificationLightX, y: height - _c },        // 4: continue down the inset edge to the bottom chamfer
        { x: width - notificationLightX - _c, y: height },        // 5: bottom-right chamfer, from the inset edge
        { x: _c, y: height },                                     // 6: across the bottom
        { x: 0, y: height - _c }                                  // 7: bottom-left chamfer
    ]

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
        // ShapePath auto-closes for fill but not for stroke — see
        // shapes/PickerPanelShape.qml's identical comment.
        PathLine { x: root._pts[0].x; y: root._pts[0].y }
    }
}

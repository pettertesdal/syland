import QtQuick
import "../"
import "../components"
import "../modules"

// The center hanging module — the clock. Always mapped/visible, sitting
// at its normal resting spot (y: 0, via HangingModule's own yShift
// defaulting to 0) whenever popups/Picker.qml is closed — same
// "permanently visible, tracks a popup's own motion" role
// windows/NotificationLight.qml plays for popups/NotificationCenter.qml.
//
// True 1:1 parity with that mechanism this time, not an approximation:
// re-checked NotificationLight's actual math (it moves the panel's own
// *full* width, 380px, ending up right at NotificationCenter's own edge
// once fully open — not a small nudge, not stopping short in some
// carved-out gap) and matched it exactly here. yShift now tracks
// picker's *entire* totalHeight, the same distance Picker's own leading
// edge travels — this clock rides all the way down to where Picker's
// own bottom edge ends up once fully open, the same way the notch rides
// all the way to NotificationCenter's own edge. windows/HangingModule.qml's
// maxYShift reserves that full distance in this window's own height so
// nothing gets clipped along the way.
HangingModule {
    id: root

    property var picker: null

    align: "center"
    boxWidth: clock.implicitWidth + Metrics.spacingMd * 2

    yShift: (picker ? picker.openProgress : 0) * (picker ? picker.totalHeight : 0)
    maxYShift: picker ? picker.totalHeight : 0

    Clock {
        id: clock
        anchors.centerIn: parent
    }
}

import QtQuick
import "../"
import "../components"
import "../modules"

// The center hanging module — just the clock, unchanged from when it
// lived inside the old full-width TopBar.
HangingModule {
    id: root

    align: "center"
    boxWidth: clock.implicitWidth + Metrics.spacingMd * 2

    Clock {
        id: clock
        anchors.centerIn: parent
    }
}

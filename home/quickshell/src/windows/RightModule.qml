import QtQuick
import "../"
import "../components"
import "../modules"

// The right hanging module: wifi / bluetooth / battery status icons,
// separated by DiagonalDivider (echoes HangingBoxShape's own cut-corner
// angle on the inside of the module). No longer grows in place into an
// expanded Bluetooth panel — that's popups/BluetoothPanel.qml now, a real
// popup dropping down from above, same as every other panel in this
// shell. HangingModule's grown/grownWidth/grownHeight capability this
// used to opt into is still there (LeftModule/CenterModule never touched
// it either), just unused here now too.
HangingModule {
    id: root

    align: "right"
    boxWidth: statusRow.implicitWidth + Metrics.spacingMd * 2

    Row {
        id: statusRow

        WifiIndicator {}
        DiagonalDivider {}
        BluetoothIndicator {}
        DiagonalDivider {}
        BatteryIndicator {}
    }

    // Unread-notification indicator, sitting at this module's own
    // bottom-right corner — the same corner popups/NotificationCenter.qml's
    // own top-right notch is deliberately aligned to share a diagonal
    // with (see that file's header comment), so this reads as "attached
    // to" the seam between the two rather than floating arbitrarily.
    // Plain on/off, not urgency-colored: matches the mockup's simple dot.
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 6
        height: 6
        color: Theme.accent
        visible: NotificationService.server.trackedNotifications.count > 0
    }
}

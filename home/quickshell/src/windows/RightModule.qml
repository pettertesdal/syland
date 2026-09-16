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
}

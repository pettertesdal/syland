import QtQuick
import "../"
import "../components"
import "../modules"

// The right hanging module: wifi / bluetooth / battery status icons,
// separated by DiagonalDivider (echoes HangingBoxShape's own cut-corner
// angle on the inside of the module). No longer grows in place into an
// expanded Bluetooth panel — that's popups/BluetoothPanel.qml now, a real
// popup dropping down from above, same as every other panel in this
// shell.
//
// Rides down as that panel grows, exactly like windows/CenterModule.qml
// rides down for popups/Picker.qml — see that file's own yShift/maxYShift
// comment for the full reasoning; bluetoothPanel.openProgress/growthRange
// here play the same role picker.openProgress/totalHeight play there.
HangingModule {
    id: root

    property var bluetoothPanel: null

    align: "right"
    boxWidth: statusRow.implicitWidth + Metrics.spacingMd * 2

    yShift: (bluetoothPanel ? bluetoothPanel.openProgress : 0) * (bluetoothPanel ? bluetoothPanel.growthRange : 0)
    maxYShift: bluetoothPanel ? bluetoothPanel.growthRange : 0

    Row {
        id: statusRow

        WifiIndicator {}
        DiagonalDivider {}
        BluetoothIndicator {}
        DiagonalDivider {}
        BatteryIndicator {}
    }
}

import QtQuick
import "../"
import "../components"
import "../modules"

// The right hanging module: wifi / bluetooth / battery, separated by
// DiagonalDivider (echoes HangingBoxShape's own cut-corner angle on the
// inside of the module).
HangingModule {
    id: root

    align: "right"
    boxWidth: statusRow.implicitWidth + Metrics.spacingMd * 2

    Row {
        id: statusRow
        anchors.centerIn: parent
        spacing: Metrics.spacingSm

        WifiIndicator {}
        DiagonalDivider {}
        BluetoothIndicator {}
        DiagonalDivider {}
        BatteryIndicator {}
    }
}

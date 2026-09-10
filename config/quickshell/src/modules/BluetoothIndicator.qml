import QtQuick
import "../"

// See WifiIndicator.qml — text label, not an icon glyph, until Nerd Font
// coverage is verified.
Row {
    spacing: Metrics.spacingXs

    Text {
        text: "BT"
        color: BluetoothStatusService.enabled ? Theme.foreground : Theme.red
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }

    Text {
        visible: BluetoothStatusService.connectedCount > 0
        text: BluetoothStatusService.connectedCount
        color: Theme.accent
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }
}

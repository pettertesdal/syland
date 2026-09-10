import QtQuick
import Quickshell.Services.UPower
import "../"

// See WifiIndicator.qml — text label, not an icon glyph, until Nerd Font
// coverage is verified. No BatteryStatusService — UPower.displayDevice is
// already the exact single-battery convenience object needed, read
// directly. Requires services.upower.enable in configuration.nix.
Row {
    spacing: Metrics.spacingXs
    visible: UPower.displayDevice !== null && UPower.displayDevice.isPresent

    Text {
        text: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging ? "CHG" : "BAT"
        color: UPower.displayDevice && UPower.displayDevice.state === UPowerDeviceState.Charging ? Theme.accent : Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }

    Text {
        // UPower reports percentage as a 0.0-1.0 fraction, not 0-100.
        text: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" : ""
        color: Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }
}

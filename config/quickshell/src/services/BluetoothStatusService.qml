pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// Same role as NetworkStatusService.qml, for Quickshell.Bluetooth.
// Requires hardware.bluetooth.enable in configuration.nix — without it
// there's no adapter, `enabled` reads false, `connectedCount` reads 0.
QtObject {
    id: root

    readonly property bool enabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

    readonly property int connectedCount: {
        var devices = Bluetooth.devices
        var count = 0
        for (var i = 0; i < devices.count; i++) {
            if (devices.get(i).connected)
                count++
        }
        return count
    }
}

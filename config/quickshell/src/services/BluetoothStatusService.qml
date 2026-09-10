pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// Same role as NetworkStatusService.qml, for Quickshell.Bluetooth. Also
// owns the two "flip a global switch" actions (power, scan) that
// popups/BluetoothPanel.qml calls — per-device actions (connect/
// disconnect/pair) are simple one-line method calls on the device object
// itself, so the panel calls those directly rather than proxying them
// through here. Requires hardware.bluetooth.enable in configuration.nix
// — without it there's no adapter, everything below reads false/0.
QtObject {
    id: root

    readonly property bool enabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property bool discovering: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false

    readonly property int connectedCount: {
        var devices = Bluetooth.devices
        var count = 0
        for (var i = 0; i < devices.count; i++) {
            if (devices.get(i).connected)
                count++
        }
        return count
    }

    function toggleAdapter() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
    }

    function toggleDiscovery() {
        if (Bluetooth.defaultAdapter)
            Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
    }
}

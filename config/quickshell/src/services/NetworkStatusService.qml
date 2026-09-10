pragma Singleton
import QtQuick
import Quickshell.Networking

// Wraps Quickshell.Networking to derive "the" current wifi state — finding
// the WifiDevice and its currently-connected WifiNetwork means walking two
// nested models, exactly the kind of thing modules/WifiIndicator.qml
// shouldn't have to do itself (modules/Clock.qml's own stated principle: a
// UI component reads from services/state, it never computes values
// itself).
//
// Device/network *lists* are effectively static for a normal desktop
// session (no hot-plugged wifi dongles expected), so the search below runs
// per read rather than being wired to every possible model-mutation
// signal — the properties actually likely to change at runtime
// (connected, signalStrength) are plain bindings to the found
// WifiNetwork's own properties, which do update live.
QtObject {
    id: root

    readonly property var _wifiDevice: {
        var devices = Networking.devices
        for (var i = 0; i < devices.count; i++) {
            var d = devices.get(i)
            if (d.type === DeviceType.Wifi)
                return d
        }
        return null
    }

    readonly property var _activeNetwork: {
        if (!_wifiDevice)
            return null
        var networks = _wifiDevice.networks
        for (var i = 0; i < networks.count; i++) {
            var n = networks.get(i)
            if (n.connected)
                return n
        }
        return null
    }

    readonly property bool connected: _activeNetwork !== null
    readonly property string ssid: _activeNetwork ? _activeNetwork.name : ""
    readonly property double signalStrength: _activeNetwork ? _activeNetwork.signalStrength : 0
}

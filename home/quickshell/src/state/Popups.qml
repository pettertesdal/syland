pragma Singleton
import QtQuick

// Single source of truth for "is the picker open" — and, as more popups
// get added later, which one.
//
// Why this needs to be a singleton rather than each Picker owning its own
// `visible` property: shell.qml runs a Variants over Quickshell.screens,
// so on a multi-monitor setup there's one Picker instance *per screen*.
// No single instance is "the" popup anymore, so IpcManager's toggle()
// can't reach into one specific Picker and flip its `visible` — instead
// every screen's Picker binds `visible: Popups.menuOpen` to this one
// shared flag, and toggling the flag opens/closes all of them together.
QtObject {
    property bool menuOpen: false

    // Whether popups/ExamplePanel.qml (the border-anchored sliding panel
    // demo) is open. Same pattern as menuOpen — a shared flag rather than
    // a property on one instance, since it's one-per-screen via Variants.
    property bool examplePanelOpen: false

    // Whether popups/NotificationCenter.qml is open. Same pattern again.
    // Note popups/NotificationToast.qml has no flag here — it isn't
    // toggled, it shows/hides itself based on whether
    // NotificationService.toastQueue is empty.
    property bool notificationCenterOpen: false

    // Whether popups/BluetoothPanel.qml — windows/RightModule.qml
    // "growing" for advanced bluetooth options — is open.
    property bool bluetoothPanelOpen: false

    // Whether popups/ThemeSwitcher.qml (sliding theme/wallpaper list) is
    // open. Same pattern again.
    property bool themeSwitcherOpen: false

    // Whether popups/TodoPanel.qml is open. Same pattern again.
    property bool todoPanelOpen: false

    function closeAll() {
        menuOpen = false
        examplePanelOpen = false
        notificationCenterOpen = false
        bluetoothPanelOpen = false
        themeSwitcherOpen = false
        todoPanelOpen = false
    }
}

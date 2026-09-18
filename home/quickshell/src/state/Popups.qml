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

    // Whether popups/BluetoothPanel.qml (drops down from above, same
    // SeamPanelShape pattern as notificationCenterOpen) is open. Used to
    // be windows/RightModule.qml growing in place instead — retired.
    property bool bluetoothPanelOpen: false

    // Whether popups/ThemeSwitcher.qml (sliding theme/wallpaper list) is
    // open. Same pattern again.
    property bool themeSwitcherOpen: false

    // Whether popups/TodoPanel.qml is open. Same pattern again.
    property bool todoPanelOpen: false

    // Whether windows/LockRetreatOverlay.qml is showing — not a normal
    // user-toggled popup like the ones above, a one-shot trigger flipped
    // true by home/quickshell-lock/LockContext.qml's own Process (via
    // IpcManager's "lock-retreat" handler) the instant login succeeds.
    // The overlay flips it back to false itself once its own retreat
    // animation finishes — deliberately left out of closeAll() below,
    // since force-closing it mid-retreat would cut the animation instead
    // of letting it finish.
    property bool lockRetreatOpen: false

    // Same pattern, entrance side: windows/LockAssemblyOverlay.qml, one-
    // shot triggered by home/syland-lock-trigger.nix's own script (the
    // lock keybind, hypridle's idle-timeout — NOT boot/lock_cmd/
    // before_sleep_cmd, see that file's own comment) via IpcManager's
    // "lock-assembly" handler. Also left out of closeAll() for the same
    // reason.
    property bool lockAssemblyOpen: false

    // Flipped true by home/quickshell-lock/LockSurface.qml's own
    // readyTrigger, once the real lock surface actually exists — tells
    // LockAssemblyOverlay.qml it's safe to hide now (see its own
    // comment). A second, distinct flag from lockAssemblyOpen since
    // hiding needs to wait on this *in addition to* the overlay's own
    // entrance animation finishing, not instead of it.
    property bool lockRealReady: false

    function closeAll() {
        menuOpen = false
        examplePanelOpen = false
        notificationCenterOpen = false
        bluetoothPanelOpen = false
        themeSwitcherOpen = false
        todoPanelOpen = false
    }
}

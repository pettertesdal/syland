pragma Singleton
import QtQuick
import Quickshell.Io

// All IpcHandlers live in exactly one place, not scattered across
// per-screen windows. If an IpcHandler with target "syland-menu" were
// instead declared inside e.g. windows/LeftModule.qml (which gets
// instantiated once per screen via Variants), Quickshell would try to
// register the same IPC target multiple times — and a single
// `qs ipc call syland-menu toggle` could fire more than once. Because
// IpcManager is a singleton
// (instantiated exactly once — see shell.qml's `property var _ipc: IpcManager`,
// which forces that to happen at startup rather than lazily), the handler
// below is registered exactly once too, no matter how many screens exist.
//
// Popups.qml lives in this same directory, so it's visible here with no
// explicit import.
QtObject {
    // Unlike Item, QtObject has no default property to hold implicit
    // children — a bare `IpcHandler { ... }` block fails to load, so it
    // needs an explicit property to attach to.
    property IpcHandler _handler: IpcHandler {
        target: "syland-menu"

        function toggle(): void {
            Popups.menuOpen = !Popups.menuOpen
        }

        function keybinds(): void {
            // Not implemented yet — syland-keybinds isn't wired into the
            // picker's UI yet. Hyprland's SUPER+SHIFT+SPACE already calls
            // this; it's just a stub until that piece gets built.
            console.log("[syland-menu] keybinds — later step, once the menu popup itself is confirmed working")
        }
    }

    // Same pattern as the syland-menu handler above: one handler here,
    // not one per Border instance, so a single `qs ipc call` can't
    // double-fire across screens. Bound to SUPER+W in
    // dot_config/hypr/keybinds.lua — the border tap zone (Border.qml)
    // still works too, they both just flip the same Popups.examplePanelOpen.
    property IpcHandler _examplePanelHandler: IpcHandler {
        target: "example-panel"

        function toggle(): void {
            Popups.examplePanelOpen = !Popups.examplePanelOpen
        }
    }

    // Bind to a Hyprland keybind the same way, e.g.:
    //   hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notification-center toggle"), { description = "Toggle notification center" })
    property IpcHandler _notificationCenterHandler: IpcHandler {
        target: "notification-center"

        function toggle(): void {
            Popups.notificationCenterOpen = !Popups.notificationCenterOpen
        }
    }

    // Bind to a Hyprland keybind the same way, e.g.:
    //   hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("qs ipc call bluetooth-panel toggle"), { description = "Toggle bluetooth panel" })
    property IpcHandler _bluetoothPanelHandler: IpcHandler {
        target: "bluetooth-panel"

        function toggle(): void {
            Popups.bluetoothPanelOpen = !Popups.bluetoothPanelOpen
        }
    }

    // Bind to a Hyprland keybind the same way, e.g.:
    //   hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs ipc call theme-switcher toggle"), { description = "Toggle theme switcher" })
    property IpcHandler _themeSwitcherHandler: IpcHandler {
        target: "theme-switcher"

        function toggle(): void {
            Popups.themeSwitcherOpen = !Popups.themeSwitcherOpen
        }
    }
}

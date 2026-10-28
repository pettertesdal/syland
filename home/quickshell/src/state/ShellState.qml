pragma Singleton
import QtQuick

// Grab-bag for small cross-cutting UI flags that many unrelated components
// might need to read, but that no single component owns. Brain_Shell's
// version of this file holds things like focusMode/dnd/wifiOn/hasBattery;
// this skeleton keeps just one placeholder property as an example — add
// more here as the shell grows, rather than inventing a new singleton per
// flag.
QtObject {
    property bool barVisible: true

    // Flipped by IpcManager's "focus-mode" IpcHandler (SUPER+F1 in
    // home/hypr/keybinds.lua). Sole source of truth for on/off state --
    // syland-focus-mode is only ever told which state to enter.
    property bool focusMode: false

    // Single display string windows/StatsModule.qml's own TextMeter
    // ("MODE" slot) reads, derived
    // from whichever mode flag above is actually active (empty when none
    // are). Add a future mode by extending this ternary chain, not by
    // giving the indicator its own copy of the logic.
    readonly property string currentMode: focusMode ? "FOCUS" : ""
}

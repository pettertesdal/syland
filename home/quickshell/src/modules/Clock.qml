import QtQuick
import "../"

// A UI component reads from services/state — it never polls or computes
// values itself. This is the same clock that used to be an inline Text
// element directly inside shell.qml; now it just displays
// ClockService.time in Theme.foreground, and both of those update it
// automatically via property binding whenever they change.
//
// "../" imports src/ (this file lives in src/modules/), which is where
// qmldir registers Theme and ClockService as singletons.
Text {
    text: ClockService.time
    color: Theme.foreground
    font.family: Metrics.fontFamily
}

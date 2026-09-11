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
}

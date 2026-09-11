pragma Singleton
import QtQuick

// The minimal "service" example: no UI at all, just a value other files
// can bind to, kept fresh by a Timer. Brain_Shell's real services
// (CpuService, NetService, DiskService, ...) are the same shape — a Timer
// driving a Process that polls something under /proc and parses the
// output into properties — just with more parsing involved. This one
// polls Qt's Date() instead of an external process, since a clock needs
// no OS call.
QtObject {
    id: root

    property string time: Qt.formatDateTime(new Date(), "hh:mm")

    // Unlike Item, QtObject has no default property to hold implicit
    // children — a bare `Timer { ... }` block here fails to load
    // ("Cannot assign to non-existent default property"). Child objects
    // need an explicit property to attach to instead.
    property Timer _timer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.time = Qt.formatDateTime(new Date(), "hh:mm")
    }
}

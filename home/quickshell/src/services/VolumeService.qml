pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

// System output volume for windows/MusicModule.qml's right-side readout
// — deliberately the actual speaker/output level (Quickshell's native
// Pipewire service), not any individual MPRIS player's own `volume`
// property: MPRIS volume is inconsistently supported (many players,
// especially browsers, don't implement it at all), and "volume" in a
// desktop shell reads as the system output level regardless of what's
// playing.
//
// PwObjectTracker is required, not optional — Pipewire.defaultAudioSink
// on its own doesn't keep its `audio` sub-interface (volume/muted)
// actively bound/updated; a node has to be explicitly tracked for that
// data to populate and change-notify. Confirmed against
// Quickshell.Services.Pipewire's own qmltypes (PwObjectTracker's
// existence, and PwNode.audio's own PwNodeAudioIface type) rather than
// guessed.
QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    property PwObjectTracker _tracker: PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
}

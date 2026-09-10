pragma Singleton
import QtQuick

// The single public color API for the rest of the shell — everything else
// should read Theme.xxx and never touch ColorLoader directly. Properties
// here are plain bindings to _loader's properties, not `property alias`,
// because QML `alias` can't target a property on another singleton's
// instance (it can only alias properties within the same object tree).
// A plain binding gets you the same live-update behavior anyway.
QtObject {
    id: root

    // ColorLoader.qml lives in this same directory, so it's visible here
    // as a type with no explicit import — QML auto-exposes every .qml
    // file in a directory to its siblings.
    property ColorLoader _loader: ColorLoader {}

    property color background: _loader.background
    property color foreground: _loader.foreground
    property color accent: _loader.accent
    property color red: _loader.red
    property color green: _loader.green
    property color yellow: _loader.yellow

    // Non-color tokens (sizing, spacing, typography, animation duration)
    // live in the sibling Metrics.qml singleton, not here.
}

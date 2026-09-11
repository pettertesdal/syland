import Quickshell
import QtQuick
import "../"

// The screen border: three thin straight strips (one PanelWindow per edge
// per screen — see shell.qml), each just a flat Metrics.borderWidth-thick
// Rectangle filled with Theme.foreground — a real 1px outline, not a
// filled block the same color as everything else. Every strip runs the
// strip's full anchored length (e.g. left/right strips span the whole
// screen height), so adjacent strips simply overlap by Metrics.borderWidth
// at each corner — harmless, since they're the same solid color.
//
// Deliberately only left/right/bottom — no top strip. Unlike the old
// full-width TopBar, the top of the screen now holds three separate
// floating windows/LeftModule.qml, CenterModule.qml, RightModule.qml) with
// gaps between them, so a continuous top line would run behind those gaps
// and look like a stray line rather than a frame. The hanging modules'
// own flush-top edges are what mark the top boundary instead.
//
// An earlier version of this file painted each strip with a QtQuick
// Canvas (arcTo) for a rounded "inverse rounded"/carved look, with
// left/right flaring outward to melt into the old full-width TopBar.
// Dropped for the terminal-minimal direction — straight lines, no curves
// — along with Metrics.cornerRadius going to 0. An even earlier version
// filled with Theme.background, which just read as empty inset space
// once the melt-into-popups effect it existed for was gone.
PanelWindow {
    id: root

    property string edge: "bottom" // "left" | "right" | "bottom"
    property int thickness: Metrics.borderWidth

    implicitWidth: (edge === "left" || edge === "right") ? thickness : 0
    implicitHeight: (edge === "bottom") ? thickness : 0

    color: "transparent"
    // Border strips are decorative, not real UI — don't reserve screen
    // space. (Nothing in this shell reserves exclusive space anymore,
    // now that the hanging modules replaced the old space-reserving
    // full-width TopBar — see components/HangingModule.qml.)
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: edge !== "right"
        right: edge !== "left"
        top: edge !== "bottom"
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    // Bottom border — centered zone: tap to toggle ExamplePanel.qml.
    // Brain_Shell's equivalent zone (its own Border.qml, bottom edge)
    // opens WallpaperPopup on hover instead of tap, with a delay timer
    // before closing so moving the mouse off doesn't instantly dismiss
    // it. Kept to a plain tap here to stay minimal — swap in a
    // HoverHandler + Timer the same way if you want that hover-open feel.
    Item {
        visible: root.edge === "bottom"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 200
        height: root.thickness

        TapHandler {
            onTapped: {
                var next = !Popups.examplePanelOpen
                Popups.closeAll()
                Popups.examplePanelOpen = next
            }
        }
    }
}

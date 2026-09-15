import QtQuick
import "../"
import "../components"

// A border-anchored sliding panel — the same technique Brain_Shell uses
// for its wallpaper selector (src/popups/WallpaperPopup.qml), trimmed
// down to the bare mechanics: no grid, no search, just a placeholder box
// that grows up out of the bottom border and fades its content in. Tap
// the middle of the bottom border strip to open it.
//
// The open/close motion itself (windowVisible/closeTimer, the transparent
// overlay window) comes from AnimatedPopup — this file only owns its own
// geometry: the `sizer` Item's width/height grow (what makes the panel
// appear to unfold out of the border) and the content opacity+slide fade
// (what makes the content feel like it's "arriving" rather than just
// popping into a fully-grown box). Terminal-minimal direction: straight
// 1px-bordered rectangle (no more PopupShape melt-into-the-border curve)
// and linear, fast easing throughout instead of InOutCubic/OutExpo.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.examplePanelOpen
    onCloseRequested: Popups.examplePanelOpen = false

    readonly property int panelWidth: 420
    readonly property int panelHeight: 240

    // Settle motion + actuation flash, adapted from popups/TodoPanel.qml
    // (the pilot for this pattern) to a grow-from-0 panel instead of an
    // x-slide — two axes (width and height) overshoot and settle
    // together via a ParallelAnimation of two settle SequentialAnimations,
    // rather than one axis. No geometry-race guard here unlike
    // TodoPanel/NotificationCenter: panelWidth/panelHeight are fixed
    // constants, not derived from parent.width/height, so there's nothing
    // that can still be stale on the very first open.
    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                closeAnim.stop()
                openAnim.restart()
            } else {
                openAnim.stop()
                closeAnim.restart()
            }
        }
    }

    Item {
        id: sizer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // Tuck inside the border strip's thickness instead of sitting
        // flush against the true screen edge — see windows/Border.qml's
        // own margins, same Metrics.borderWidth constant.
        anchors.bottomMargin: Metrics.borderWidth
        clip: true

        width: 0
        height: 0

        ParallelAnimation {
            id: openAnim
            onFinished: sizer.flashBorder()
            SequentialAnimation {
                NumberAnimation {
                    target: sizer; property: "width"
                    to: root.panelWidth + Metrics.settleOvershoot
                    duration: Metrics.animDuration
                    easing.type: Easing.Linear
                }
                NumberAnimation {
                    target: sizer; property: "width"
                    to: root.panelWidth
                    duration: Metrics.settleDuration
                    easing.type: Easing.Linear
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: sizer; property: "height"
                    to: root.panelHeight + Metrics.settleOvershoot
                    duration: Metrics.animDuration
                    easing.type: Easing.Linear
                }
                NumberAnimation {
                    target: sizer; property: "height"
                    to: root.panelHeight
                    duration: Metrics.settleDuration
                    easing.type: Easing.Linear
                }
            }
        }

        ParallelAnimation {
            id: closeAnim
            NumberAnimation { target: sizer; property: "width"; to: 0; duration: Metrics.animDuration; easing.type: Easing.Linear }
            NumberAnimation { target: sizer; property: "height"; to: 0; duration: Metrics.animDuration; easing.type: Easing.Linear }
        }

        property color borderColor: Theme.foreground

        function flashBorder() {
            flashFade.stop()
            borderColor = Theme.accent
            flashFade.restart()
        }

        ColorAnimation {
            id: flashFade
            target: sizer; property: "borderColor"
            to: Theme.foreground
            duration: Metrics.settleDuration * 3
            easing.type: Easing.Linear
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 1
            border.color: sizer.borderColor
        }

        Item {
            anchors.fill: parent
            anchors.margins: Metrics.spacingMd

            opacity: root.openFlag ? 1 : 0
            transform: Translate {
                y: root.openFlag ? 0 : 20
                Behavior on y { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
            }
            Behavior on opacity {
                NumberAnimation { duration: root.openFlag ? Metrics.animDuration * 0.5 : Metrics.animDuration * 0.15 }
            }

            Text {
                anchors.centerIn: parent
                text: "Example panel — replace with real content"
                color: Theme.foreground
                font.family: Metrics.fontFamily
                wrapMode: Text.WordWrap
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}

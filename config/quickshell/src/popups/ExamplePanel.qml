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

    Item {
        id: sizer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // Tuck inside the border strip's thickness instead of sitting
        // flush against the true screen edge — see windows/Border.qml's
        // own margins, same Metrics.borderWidth constant.
        anchors.bottomMargin: Metrics.borderWidth
        clip: true

        width: root.openFlag ? root.panelWidth : 0
        height: root.openFlag ? root.panelHeight : 0
        Behavior on width { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
        Behavior on height { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 1
            border.color: Theme.foreground
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

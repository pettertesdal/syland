import QtQuick
import Quickshell.Io
import "../"
import "../components"

// Sliding theme/wallpaper switcher. All the actual work — rendering
// colors for quickshell/ghostty/hyprland, calling awww, calling
// `hyprctl reload config-only` — happens in the syland-theme-apply
// backend (home/theme-apply.nix); this file is just a thin UI over its
// list-themes/list-images/current/apply subcommands.
//
// Same AnimatedPopup/ExamplePanel pattern as every other popup here: a
// bottom-anchored sizer that grows from 0, plain 1px-bordered Rectangle
// (no Shape — SeamPanelShape is tailored to RightModule's own corner and
// doesn't fit a freestanding popup like this one).
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.themeSwitcherOpen
    onCloseRequested: Popups.themeSwitcherOpen = false

    readonly property int panelWidth: 560
    readonly property int panelHeight: 260
    readonly property int thumbWidth: 140

    property var themes: []
    property var images: []
    property string selectedTheme: ""
    property string currentTheme: ""
    property string currentImage: ""
    // 0 = theme list, 1 = image list for selectedTheme
    property int viewLevel: 0

    onOpenFlagChanged: {
        if (openFlag) {
            viewLevel = 0
            listThemesProc.exec(["syland-theme-apply", "list-themes"])
            currentProc.exec(["syland-theme-apply", "current"])
        }
    }

    function selectTheme(name) {
        selectedTheme = name
        currentTheme = name
        // "apply <theme>" with no image arg applies the theme's default
        // background — list-images always returns that entry first, so
        // this keeps the highlighted thumbnail in sync without waiting
        // on a separate `current` round-trip.
        currentImage = ""
        applyProc.exec(["syland-theme-apply", "apply", name])
        listImagesProc.exec(["syland-theme-apply", "list-images", name])
        viewLevel = 1
    }

    function selectImage(name) {
        currentImage = name
        applyProc.exec(["syland-theme-apply", "apply", selectedTheme, name])
    }

    function parseJsonLines(text) {
        return text.split("\n")
            .filter(function (line) { return line.trim().length > 0 })
            .map(function (line) { return JSON.parse(line) })
    }

    Process {
        id: listThemesProc
        stdout: StdioCollector {
            onStreamFinished: root.themes = root.parseJsonLines(text)
        }
    }
    Process {
        id: listImagesProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.images = root.parseJsonLines(text)
                if (root.currentImage === "" && root.images.length > 0)
                    root.currentImage = root.images[0].name
            }
        }
    }
    Process {
        id: currentProc
        stdout: StdioCollector {
            onStreamFinished: {
                var c = text.trim().length > 0 ? JSON.parse(text) : {}
                root.currentTheme = c.theme || ""
                root.currentImage = c.image || ""
            }
        }
    }
    // Fire-and-forget — command is set via exec() right before it runs.
    Process { id: applyProc }

    Item {
        id: sizer
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Metrics.borderWidth
        clip: true

        width: root.openFlag ? root.panelWidth : 0
        height: root.openFlag ? root.panelHeight : 0
        Behavior on width { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
        Behavior on height { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 1
            border.color: Theme.foreground
        }

        // Two-panel horizontal slider: an Item 2x panelWidth wide,
        // translated by -panelWidth * viewLevel. Panel 0 = theme list,
        // panel 1 = image list.
        Item {
            width: root.panelWidth * 2
            height: parent.height
            x: -root.viewLevel * root.panelWidth
            Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

            Item {
                x: 0
                width: root.panelWidth
                height: parent.height

                ListView {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: Metrics.spacingSm
                    model: root.themes

                    delegate: Rectangle {
                        // Required — this file sits inside shell.qml's
                        // per-screen Scope { required property var
                        // modelData }, which shadows a delegate's own
                        // implicit modelData otherwise.
                        required property var modelData

                        width: root.thumbWidth
                        height: ListView.view.height
                        color: "transparent"
                        border.width: modelData.name === root.currentTheme ? 2 : 1
                        border.color: modelData.name === root.currentTheme ? Theme.accent : Theme.foreground

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            anchors.bottomMargin: 20
                            fillMode: Image.PreserveAspectCrop
                            source: "file://" + modelData.default_image
                        }
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            // has_variation means this theme has at least
                            // one hidden <name>-N.<ext> picture, cycled
                            // through with the (user-added) toggle keybind
                            // rather than shown here as a normal option.
                            text: modelData.name + (modelData.has_variation ? " *" : "")
                            color: Theme.foreground
                            font.family: Metrics.fontFamily
                            font.pixelSize: Metrics.fontSizeSmall
                        }
                        TapHandler { onTapped: root.selectTheme(modelData.name) }
                    }
                }
            }

            Item {
                x: root.panelWidth
                width: root.panelWidth
                height: parent.height
                anchors.margins: Metrics.spacingMd

                Text {
                    id: backLabel
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: Metrics.spacingMd
                    text: "‹ " + root.selectedTheme
                    color: Theme.accent
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeRegular

                    TapHandler { onTapped: root.viewLevel = 0 }
                }

                ListView {
                    anchors.top: backLabel.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Metrics.spacingMd
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: Metrics.spacingSm
                    model: root.images

                    delegate: Rectangle {
                        required property var modelData

                        width: root.thumbWidth
                        height: ListView.view.height
                        color: "transparent"
                        border.width: modelData.name === root.currentImage ? 2 : 1
                        border.color: modelData.name === root.currentImage ? Theme.accent : Theme.foreground

                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            fillMode: Image.PreserveAspectCrop
                            source: "file://" + modelData.path
                        }
                        TapHandler { onTapped: root.selectImage(modelData.name) }
                    }
                }
            }
        }
    }
}

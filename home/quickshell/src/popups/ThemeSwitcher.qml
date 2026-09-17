import QtQuick
import Quickshell.Io
import "../"
import "../components"
import "../shapes"

// Sliding theme/wallpaper switcher. All the actual work — rendering
// colors for quickshell/ghostty/hyprland, calling awww, calling
// `hyprctl reload config-only` — happens in the syland-theme-apply
// backend (home/theme-apply.nix); this file is just a thin UI over its
// list-themes/list-images/current/apply subcommands.
//
// Container mirrors popups/Picker.qml, flipped vertically: rises from
// the bottom (instead of falling from the top) into the gap
// windows/StatsModule.qml's own two instances leave, with
// shapes/PickerPanelShape.qml's own flipV: true so the ears sit at the
// bottom (touching StatsModule, the way Picker's ears touch
// windows/MusicModule.qml) and the main body grows upward from there.
// Same slide + overshoot + settle-flash motion as Picker too — see that
// file's own openAnim/flashBorder for the pattern this mirrors. Only the
// content below (the two-panel theme/image slider, and every Process/
// function driving it) is unchanged from before.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }

    openFlag: Popups.themeSwitcherOpen
    onCloseRequested: Popups.themeSwitcherOpen = false

    readonly property int outerEdgeDrop: Metrics.moduleContentHeight
    readonly property int outerEdgeWidth: 13
    readonly property int mainBodyHeight: 260
    readonly property int totalHeight: outerEdgeDrop + mainBodyHeight
    // No centerModule to key off (no bottom-row clock) — mirrors
    // windows/StatsModule.qml's own centerX substitution: same formula
    // popups/Picker.qml uses (centerGap*2 + boxWidth + 16), with
    // boxWidth: 0 since there's no center widget here.
    readonly property int panelWidth: Metrics.centerGap * 2 + 16
    // The slider's own usable width — panelWidth minus both ears' own
    // margin (outerEdgeWidth + spacingMd on each side), same inset
    // popups/Picker.qml's own content Column uses. Narrower than the old
    // fixed 560 now that panelWidth is derived to snugly fit the gap
    // rather than picked freely — thumbWidth/spacing below still apply,
    // just fitting fewer thumbnails per row.
    readonly property int contentWidth: panelWidth - 2 * (outerEdgeWidth + Metrics.spacingMd)
    readonly property int thumbWidth: 140

    property var themes: []
    property var images: []
    property string selectedTheme: ""
    property string currentTheme: ""
    property string currentImage: ""
    // 0 = theme list, 1 = image list for selectedTheme
    property int viewLevel: 0

    // Consolidated into one Connections block rather than the plain
    // onOpenFlagChanged this used to be (still works fine alongside
    // AnimatedPopup's own internal handler of the same name — this file
    // is live proof of that — but Connections is now the pattern every
    // sibling popup uses, and folding the settle trigger in here keeps
    // "what happens on open" in one place instead of two separate
    // handlers with an unclear relative order).
    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                viewLevel = 0
                listThemesProc.exec(["syland-theme-apply", "list-themes"])
                currentProc.exec(["syland-theme-apply", "current"])
                closeAnim.stop()
                panel.beginOpen()
            } else {
                openAnim.stop()
                pendingOpen.enabled = false
                closeAnim.restart()
            }
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
        id: panel
        // Centered on the screen's own midpoint — mirrors
        // windows/StatsModule.qml's own centerX (no centerModule to key
        // off here either).
        x: parent.width / 2 - root.panelWidth / 2
        width: root.panelWidth
        height: root.totalHeight

        readonly property int restY: parent.height - height
        readonly property int hiddenY: parent.height
        y: hiddenY

        // First-open geometry-race guard — same fact
        // popups/NotificationCenter.qml's own openProgress comment
        // documents: AnimatedPopup's PanelWindow starts `visible: false`
        // and doesn't get a real Wayland configure (real width/height)
        // until first opened, so parent.height sits at a placeholder
        // (100) the whole time this window has never been mapped.
        // hiddenY/restY above both key off parent.height, so animating
        // immediately on that first open grabbed the placeholder as the
        // animation's implicit "from" (y's current value at that
        // instant) — starting near the TOP of the screen instead of
        // below it — even though restY itself later resolved correctly
        // once actually read after layout settled, which is exactly why
        // the *end* position always looked right while the *start*
        // didn't. Confirmed live: this is what "the animation comes from
        // the top" actually was, not something a hiddenY offset fixes.
        function beginOpen() {
            if (parent.height >= height) {
                openAnim.restart()
            } else {
                pendingOpen.enabled = true
            }
        }

        Connections {
            id: pendingOpen
            target: panel.parent
            enabled: false
            function onHeightChanged() {
                if (root.openFlag && panel.parent.height >= panel.height) {
                    pendingOpen.enabled = false
                    openAnim.restart()
                }
            }
        }

        SequentialAnimation {
            id: openAnim
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "y"
                // - not +: this panel rises UP into view (y decreasing
                // toward restY), so overshooting past restY means going
                // further up than rest, then springing back down — the
                // mirror image of popups/Picker.qml's own "+" overshoot,
                // which falls down instead of rising up.
                to: panel.restY - Metrics.settleOvershoot
                duration: Metrics.animDuration
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: panel; property: "y"
                to: panel.restY
                duration: Metrics.settleDuration
                easing.type: Easing.Linear
            }
        }

        NumberAnimation {
            id: closeAnim
            target: panel; property: "y"
            to: panel.hiddenY
            duration: Metrics.animDuration
            easing.type: Easing.Linear
        }

        property color borderColor: Theme.foreground

        function flashBorder() {
            flashFade.stop()
            borderColor = Theme.accent
            flashFade.restart()
        }

        ColorAnimation {
            id: flashFade
            target: panel; property: "borderColor"
            to: Theme.foreground
            duration: Metrics.settleDuration * 3
            easing.type: Easing.Linear
        }

        PickerPanelShape {
            width: panel.width
            height: root.totalHeight
            outerEdgeDrop: root.outerEdgeDrop
            outerEdgeWidth: root.outerEdgeWidth
            fillColor: Theme.background
            strokeColor: panel.borderColor
            flipV: true
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        // Ears are at the bottom now (flipV), so the inset that was
        // popups/Picker.qml's own topMargin is bottomMargin here instead,
        // and vice versa.
        Item {
            anchors.top: parent.top
            anchors.topMargin: Metrics.spacingMd
            anchors.left: parent.left
            anchors.leftMargin: root.outerEdgeWidth + Metrics.spacingMd
            anchors.right: parent.right
            anchors.rightMargin: root.outerEdgeWidth + Metrics.spacingMd
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.outerEdgeDrop + Metrics.spacingMd
            clip: true

            // Two-panel horizontal slider: an Item 2x contentWidth wide,
            // translated by -contentWidth * viewLevel. Panel 0 = theme
            // list, panel 1 = image list.
            Item {
                width: root.contentWidth * 2
                height: parent.height
                x: -root.viewLevel * root.contentWidth
                Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

                Item {
                    x: 0
                    width: root.contentWidth
                    height: parent.height

                    ListView {
                        anchors.fill: parent
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
                    x: root.contentWidth
                    width: root.contentWidth
                    height: parent.height

                    Text {
                        id: backLabel
                        anchors.top: parent.top
                        anchors.left: parent.left
                        text: "‹ " + root.selectedTheme
                        color: Theme.accent
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeRegular

                        TapHandler { onTapped: root.viewLevel = 0 }
                    }

                    ListView {
                        anchors.top: backLabel.bottom
                        anchors.topMargin: Metrics.spacingSm
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
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
}

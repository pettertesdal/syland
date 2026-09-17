// STEP 5 of the picker build-out (Section 8): declarative JSONC menu
// (dotted-key hierarchy) instead of a script-tree, fetched ONCE per open
// rather than per navigation step, plus a genuine global-search mode.
//
// Usage from shell.qml:
//   Picker { centerModule: centerModule }
// Opening/closing is no longer done by poking `visible` directly (that
// only worked back when there was exactly one Picker instance) — this
// file binds openFlag: Popups.menuOpen, and IpcManager.qml's toggle()
// flips that shared flag instead. See state/Popups.qml for why.
//
// Two distinct modes, not one filtered list:
//   BROWSE (search empty, in root/tree level): immediate children of the
//     current dotted-key prefix only, plus Apps/Context categories at root.
//   GLOBAL SEARCH (search non-empty, in root/tree level): every menu.jsonc
//     entry at ANY depth, merged with every installed app, matched by
//     substring — this is what makes typing "per" surface both the
//     "personal" folder and the "personal.notes" leaf, plus any app whose
//     name contains "per".
// Apps/Context levels keep local-filter-only behavior once drilled into,
// since global reach doesn't make sense after explicitly choosing a
// category.
//
// Entry shapes flowing through this file:
//   { label, icon, kind: "dir",  path }            -- menu.jsonc folder, drill in
//   { label, icon, kind: "leaf", path, action }    -- menu.jsonc leaf, run its action
//   { label, kind: "provider", provider }          -- synthetic root category, drill in
//   { label, kind: "app",     entry }              -- native DesktopEntry, entry.execute()
//   { label, kind: "context-item", path }          -- a context project dir, syland-context set
//
// Now a proper AnimatedPopup (was a raw ad hoc PanelWindow with a plain
// Rectangle fill and hardcoded hex colors) — falls into place from above
// the screen the same way popups/TodoPanel.qml/NotificationCenter.qml
// slide in from the side, just on the y axis instead of x. Sized to fit
// snugly in the gap windows/MusicModule.qml's two instances already
// leave around windows/CenterModule.qml (Metrics.centerGap on each
// side), and exposes openProgress the same way NotificationCenter does
// for windows/NotificationLight.qml — CenterModule's own clock rides
// down with it (see that file's own comment), landing once this panel's
// own "ears" (shapes/PickerPanelShape.qml's outerEdgeDrop region) reach
// the same height windows/MusicModule.qml already sits at.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"
import "../components"
import "../shapes"

AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    focusable: true

    property var centerModule: null

    openFlag: Popups.menuOpen
    onCloseRequested: Popups.menuOpen = false

    readonly property int outerEdgeDrop: Metrics.moduleContentHeight
    readonly property int outerEdgeWidth: 13 // shapes/PickerPanelShape.qml's own default (the tail's own protrusion length) — named here too since the content column needs to inset by the same amount
    readonly property int mainBodyHeight: 360
    readonly property int totalHeight: outerEdgeDrop + mainBodyHeight
    // No plain "+ outerEdgeWidth" term here — the ears are inset *within*
    // the shape's own 0..width bounds (see shapes/PickerPanelShape.qml's
    // _pts), not additive to them, so centerGap*2 + boxWidth alone already
    // puts each ear tip exactly on MusicModule.qml's own box boundary. A
    // stray "13 +" here once pushed both ear tips 6.5px past that
    // boundary into each MusicModule's own territory (confirmed via
    // pixel-level screenshot analysis — that overlap is what read as
    // "missing top border on the left ear," since MusicModule-left's
    // window, stacked above Picker's, was painting over Picker's own
    // top-edge stroke there).
    //
    // But landing exactly on the box boundary isn't right either — and
    // matching the tail's tip (tried first, +10 total) isn't either, for
    // a subtler reason: outerEdgeDrop already caps the ear at the same
    // height (ed ≈ 16) where MusicModuleShape.qml's own tailTopY sits, so
    // for the ear's own full height (y: 0..16) MusicModule hasn't started
    // poking its tail out yet — its actual silhouette there is bodyRight,
    // tailDepth (8px) shy of the box edge, not the box edge itself and
    // not the tail's tip either (that only exists below tailTopY). The
    // ear tip needs to reach bodyRight, i.e. tailDepth in from the box
    // boundary on each side — confirmed by pixel measurement: at +10 the
    // ear sat 2-3px short of MusicModule-left's own stroke.
    //
    // The nice side effect: since outerEdgeWidth (13, right above) was
    // already chosen to equal tailExtend, once the ear tip lands on
    // bodyRight, the main body's own edge (ear tip + outerEdgeWidth)
    // lands exactly on tailTipX (bodyRight + tailExtend) too — one
    // correction satisfies both, rather than needing two separate ones.
    // tailDepth/tailExtend aren't exposed as shared constants
    // (MusicModuleShape.qml hardcodes both), so this 16 (2 * tailDepth)
    // is a derived literal, not a token ref.
    readonly property int panelWidth: centerModule ? Metrics.centerGap * 2 + centerModule.boxWidth + 16 : 480

    // 0 when fully closed/unmapped, 1 when fully settled open — tracks
    // panel.y directly, exactly like NotificationCenter's own
    // openProgress tracks panel.x. windows/CenterModule.qml reads this
    // to ride down in sync.
    readonly property real openProgress: panel.restY > panel.hiddenY
        ? (panel.y - panel.hiddenY) / (panel.restY - panel.hiddenY)
        : 0

    property var allMenuEntries: []  // full flat menu.jsonc, fetched once per open
    property var entries: []         // current provider-specific list (context)
    property int currentIndex: 0
    property var stack: [{ type: "root" }]
    readonly property var currentLevel: stack[stack.length - 1]
    readonly property bool searching: searchField.text !== ""

    // Reactive, not a one-time snapshot: DesktopEntries.applications may
    // still be indexing when "Apps" is first selected, so this needs to
    // recompute automatically whenever the index actually finishes,
    // rather than capturing whatever was there at button-press time.
    readonly property var appEntries: [...DesktopEntries.applications.values]
        .filter(function (e) { return e.name })
        .sort(function (a, b) { return a.name.localeCompare(b.name) })
        .map(function (e) { return { label: e.name, kind: "app", entry: e } })

    // Immediate children of the current dotted-key prefix (browse mode).
    readonly property var browseChildren: {
        var prefix = currentLevel.type === "tree" ? currentLevel.path : ""
        var children = allMenuEntries.filter(function (e) {
            if (prefix === "") return e.path.indexOf(".") === -1
            if (e.path.indexOf(prefix + ".") !== 0) return false
            return e.path.slice(prefix.length + 1).indexOf(".") === -1
        })
        if (currentLevel.type === "root") {
            children = children.concat([
                { label: "Apps", kind: "provider", provider: "apps" },
                { label: "Context", kind: "provider", provider: "context" }
            ])
        }
        return children
    }

    // Every menu.jsonc entry at any depth, plus every app — global search.
    readonly property var globalSearchPool: allMenuEntries.concat(appEntries)

    readonly property var activeEntries: {
        if (currentLevel.type === "apps") return appEntries
        if (currentLevel.type === "context") return entries
        return searching ? globalSearchPool : browseChildren
    }

    readonly property var filteredEntries: activeEntries.filter(function (e) {
        if (searchField.text === "") return true
        var q = searchField.text.toLowerCase()
        var labelMatch = e.label.toLowerCase().includes(q)
        var pathMatch = e.path ? e.path.toLowerCase().includes(q) : false
        return labelMatch || pathMatch
    })

    // Settle motion + first-open geometry-race guard — ported from
    // popups/TodoPanel.qml, on the y axis instead of x. See that file's
    // own comments for the full reasoning behind each piece.
    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                stack = [{ type: "root" }]
                searchField.text = ""
                currentIndex = 0
                menuFetchProc.running = true // full menu.jsonc fetched once per open
                closeAnim.stop()
                panel.beginOpen()
                searchField.forceActiveFocus()
            } else {
                openAnim.stop()
                closeAnim.restart()
            }
        }
    }

    function pushLevel(level) {
        stack = stack.concat([level])
        searchField.text = ""
        currentIndex = 0
        if (level.type === "context") contextListProc.running = true
    }

    function popLevel() {
        if (stack.length <= 1) return
        stack = stack.slice(0, -1)
        searchField.text = ""
        currentIndex = 0
    }

    function runSelection() {
        var item = filteredEntries[currentIndex]
        if (!item) return

        if (item.kind === "dir") {
            pushLevel({ type: "tree", path: item.path })
        } else if (item.kind === "provider") {
            pushLevel({ type: item.provider })
        } else if (item.kind === "leaf") {
            runProc.command = ["syland-menu", "run", item.action]
            runProc.running = true
            Popups.menuOpen = false
        } else if (item.kind === "app") {
            item.entry.execute()
            Popups.menuOpen = false
        } else if (item.kind === "context-item") {
            setContextProc.command = ["syland-context", "set", item.path]
            setContextProc.running = true
            Popups.menuOpen = false
        }
    }

    Process {
        id: menuFetchProc
        command: ["syland-menu", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function (l) { return l.length > 0 })
                root.allMenuEntries = lines.map(function (l) { return JSON.parse(l) })
            }
        }
    }

    Process {
        id: contextListProc
        command: ["syland-context", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function (l) { return l.length > 0 })
                root.entries = lines.map(function (l) {
                    var e = JSON.parse(l)
                    return { label: e.label, kind: "context-item", path: e.path }
                })
            }
        }
    }

    // Fire-and-forget processes: command is set right before each run.
    Process { id: runProc }
    Process { id: setContextProc }

    Item {
        id: panel
        width: root.panelWidth
        height: root.totalHeight
        // boxWidth/2 cancels out algebraically (panelWidth is centerGap*2
        // + boxWidth, centered on the same boxX + boxWidth/2 midpoint),
        // leaving a plain integer boxX - centerGap — no fractional pixel
        // possible, so no Math.round/floor rounding needed. The earlier
        // left/right border mismatch this used to paper over (via a
        // Math.floor(...) + 1 fudge) was actually panelWidth carrying a
        // stray extra 13px, which is what broke the cancellation and
        // produced a .5px offset — see panelWidth's own comment.
        x: root.centerModule
            ? root.centerModule.boxX + root.centerModule.boxWidth / 2 - width / 2
            : 0

        readonly property int restY: 0
        readonly property int hiddenY: -root.totalHeight
        y: hiddenY

        SequentialAnimation {
            id: openAnim
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "y"
                // + not -: panel falls DOWN into view (y increasing
                // toward restY), so overshooting past restY means going
                // further down than rest, then springing back up — same
                // "overshoot past, settle back toward" shape
                // popups/NotificationCenter.qml's own openAnim uses, just
                // mirrored for a vertical instead of horizontal slide.
                to: panel.restY + Metrics.settleOvershoot
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

        function beginOpen() {
            openAnim.restart()
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
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            anchors.top: parent.top
            anchors.topMargin: root.outerEdgeDrop + Metrics.spacingMd
            anchors.left: parent.left
            // Inset by outerEdgeWidth, not just the ordinary spacingMd
            // padding every other popup uses — the shape's own main body
            // (below the ears) is narrower than panel's full width by
            // outerEdgeWidth on each side (shapes/PickerPanelShape.qml's
            // own _pts step inward there); using the plain padding alone
            // let content render past the shape's own edges.
            anchors.leftMargin: root.outerEdgeWidth + Metrics.spacingMd
            anchors.right: parent.right
            anchors.rightMargin: root.outerEdgeWidth + Metrics.spacingMd
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.spacingMd
            spacing: Metrics.spacingSm

            Text {
                visible: root.stack.length > 1 || root.searching
                text: root.searching
                    ? "Searching everywhere"
                    : root.stack.map(function (l) { return l.type === "tree" ? l.path : l.type }).join(" > ")
                color: Theme.foreground
                opacity: 0.6
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeSmall
            }

            TextField {
                id: searchField
                width: parent.width
                placeholderText: "Search..."

                onTextChanged: root.currentIndex = 0

                Keys.onEscapePressed: Popups.menuOpen = false
                Keys.onReturnPressed: root.runSelection()
                Keys.onDownPressed: root.currentIndex = Math.min(root.currentIndex + 1, root.filteredEntries.length - 1)
                Keys.onUpPressed: root.currentIndex = Math.max(root.currentIndex - 1, 0)
                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Backspace && searchField.text === "" && root.stack.length > 1) {
                        root.popLevel()
                        event.accepted = true
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - searchField.height - Metrics.spacingSm * 2
                clip: true
                // Deliberately NOT `currentIndex: root.currentIndex` —
                // confirmed live elsewhere in this shell
                // (popups/NotificationCenter.qml's own history) that
                // binding ListView.currentIndex directly engages the
                // view's own built-in keyboard-navigation/focus
                // machinery and steals active focus away from whatever
                // element (searchField here) is supposed to hold it.
                // Selection is plain-index only, driven by root's own
                // Keys.onUpPressed/onDownPressed above; each delegate
                // just compares its own index against it for highlight.
                model: root.filteredEntries
                delegate: Item {
                    id: entryRow
                    required property int index
                    required property var modelData

                    width: ListView.view.width
                    height: Metrics.moduleHeight

                    // A separate highlight overlay, not the row's own
                    // opacity — applying opacity directly to this item
                    // would also fade its Text child down to near-
                    // invisible, exactly backwards from a highlight
                    // (confirmed the mistake while reviewing before ever
                    // shipping it).
                    Rectangle {
                        anchors.fill: parent
                        visible: entryRow.index === root.currentIndex
                        color: Theme.accent
                        opacity: 0.15
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Metrics.spacingSm
                        text: (entryRow.modelData.icon ? entryRow.modelData.icon + "  " : "") + entryRow.modelData.label
                            + (entryRow.modelData.kind === "dir" || entryRow.modelData.kind === "provider" ? "  >" : "")
                        color: Theme.foreground
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeRegular
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.currentIndex = entryRow.index
                            root.runSelection()
                        }
                    }
                }
            }
        }
    }
}

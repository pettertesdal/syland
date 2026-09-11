// STEP 5 of the picker build-out (Section 8): declarative JSONC menu
// (dotted-key hierarchy) instead of a script-tree, fetched ONCE per open
// rather than per navigation step, plus a genuine global-search mode.
//
// Usage from shell.qml:
//   Picker { targetWindow: centerModule }
// Opening/closing is no longer done by poking `visible` directly (that
// only worked back when there was exactly one Picker instance) — this
// file binds `visible: Popups.menuOpen`, and IpcManager.qml's toggle()
// flips that shared flag instead. See state/Popups.qml for why.
//
// Gotcha this relied on getting right: `visible` here is a *binding*
// (`visible: Popups.menuOpen`), not a plain assigned value. Imperatively
// writing `root.visible = false` anywhere below would silently destroy
// that binding — QML property bindings are replaced, not merged, by a
// later imperative assignment — leaving `visible` stuck at a literal
// `false` forever, so the picker could never be reopened. Every place
// that used to say `root.visible = false` now instead sets
// `Popups.menuOpen = false`, which changes the *source* the binding reads
// from, leaving the binding itself intact.
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
// See prior comments in this file's history for why PanelWindow (not
// PopupWindow) and Picker (not Menu) — both confirmed via real errors.

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

PanelWindow {
    id: root
    implicitWidth: 480
    implicitHeight: 360
    visible: Popups.menuOpen
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    property var targetWindow: null
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

    anchors { top: true }
    margins.top: targetWindow ? targetWindow.height : 0
    margins.left: 400 // rough centering placeholder — refine once behavior is confirmed

    onVisibleChanged: if (visible) {
        stack = [{ type: "root" }]
        searchField.text = ""
        currentIndex = 0
        menuFetchProc.running = true // full menu.jsonc fetched once per open
        searchField.forceActiveFocus()
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

    Rectangle {
        anchors.fill: parent
        color: Theme.background

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
                visible: root.stack.length > 1 || root.searching
                text: root.searching
                    ? "Searching everywhere"
                    : root.stack.map(function (l) { return l.type === "tree" ? l.path : l.type }).join(" > ")
                color: "#7f849c"
                font.pixelSize: 11
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
                height: parent.height - searchField.height - 8
                model: root.filteredEntries
                currentIndex: root.currentIndex
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 32
                    color: index === root.currentIndex ? "#313244" : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: (modelData.icon ? modelData.icon + "  " : "") + modelData.label
                            + (modelData.kind === "dir" || modelData.kind === "provider" ? "  >" : "")
                        color: Theme.foreground
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.currentIndex = index
                            root.runSelection()
                        }
                    }
                }
            }
        }
    }
}

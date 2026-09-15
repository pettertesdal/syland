import QtQuick
import "../"
import "../components"
import "../shapes"

// The TODO panel: same SeamPanelShape chrome and slide-from-the-right
// mechanics as NotificationCenter.qml. Two sections instead of one flat
// list — the active project's tasks (TodoService.contextTasks, named by
// TodoService.currentProject) above a divider, then the always-visible
// general list (TodoService.generalTasks) below — flattened into a single
// ListView with a {header, text}/{task} row model rather than two nested
// ListViews, since QML sizes two independent ListViews inside a Column
// awkwardly (each would need its own explicit height) for no real benefit
// here.
AnimatedPopup {
    id: root

    anchors { top: true; left: true; right: true; bottom: true }
    // AnimatedPopup's own PanelWindow base doesn't turn this on (most
    // consumers are click-to-dismiss only) — this panel needs real
    // keyboard input, same as Picker.qml sets it explicitly for itself.
    focusable: true

    openFlag: Popups.todoPanelOpen
    onCloseRequested: Popups.todoPanelOpen = false

    readonly property int panelWidth: 380

    // Re-pull from `syland-todo list` every time the panel opens — the
    // active project (syland-context) may have changed since the last
    // open. Same spot Picker.qml re-runs its own list processes. Also
    // hands keyboard focus straight to addField, mirroring Picker.qml's
    // own searchField.forceActiveFocus() on open — this panel is meant to
    // be driven entirely from the keyboard, no click required first.
    //
    // A Connections block rather than redeclaring `onOpenFlagChanged`
    // directly here: AnimatedPopup.qml already has its own internal
    // onOpenFlagChanged driving windowVisible/closeTimer, and Connections
    // is the idiomatic way to attach an independent handler to a signal
    // without risking a collision with that existing one.
    Connections {
        target: root
        function onOpenFlagChanged() {
            if (root.openFlag) {
                TodoService.refresh()
                addField.forceActiveFocus()
            }
        }
    }

    readonly property var rows: {
        var out = []
        out.push({ kind: "header", text: TodoService.currentProject ? TodoService.currentProject : "No active project" })
        for (var i = 0; i < TodoService.contextTasks.length; i++)
            out.push({ kind: "task", task: TodoService.contextTasks[i] })
        out.push({ kind: "header", text: "General" })
        for (var j = 0; j < TodoService.generalTasks.length; j++)
            out.push({ kind: "task", task: TodoService.generalTasks[j] })
        return out
    }

    // Keyboard-selected row, an index into `rows` that always points at a
    // "task" row (never a header) — the counterpart to Picker.qml's own
    // currentIndex/filteredEntries pairing.
    property int currentIndex: -1

    readonly property var taskRowIndices: {
        var out = []
        for (var i = 0; i < rows.length; i++)
            if (rows[i].kind === "task") out.push(i)
        return out
    }

    // Keeps currentIndex pointing at a real task whenever the task list
    // changes shape (panel just opened, a task got added/completed and
    // TodoService.refresh() pulled in new data, ...) — without this,
    // completing the previously-selected task would leave currentIndex
    // dangling on a now-stale row index.
    onRowsChanged: {
        var idxs = root.taskRowIndices
        if (idxs.indexOf(root.currentIndex) === -1)
            root.currentIndex = idxs.length > 0 ? idxs[0] : -1
    }

    // Clamped, not wrapping — same choice Picker.qml's own
    // Keys.onDownPressed/onUpPressed already made with Math.min/Math.max.
    function moveSelection(delta) {
        var idxs = root.taskRowIndices
        if (idxs.length === 0) return
        var pos = idxs.indexOf(root.currentIndex)
        var next = pos === -1 ? 0 : Math.min(Math.max(pos + delta, 0), idxs.length - 1)
        root.currentIndex = idxs[next]
    }

    Item {
        id: panel
        width: root.panelWidth
        height: parent.height - root.panelWidth
        x: root.openFlag ? (parent.width - width) : parent.width
        Behavior on x { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        SeamPanelShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: Theme.foreground
        }

        // Swallow clicks on the panel itself so they don't fall through
        // to AnimatedPopup's full-window dismiss MouseArea.
        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            id: header
            anchors.top: parent.top
            anchors.topMargin: Metrics.moduleHeight + Metrics.spacingMd
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Metrics.spacingMd
            spacing: Metrics.spacingSm

            Text {
                text: "TODO"
                color: Theme.foreground
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeLarge
            }

            Row {
                width: parent.width
                spacing: Metrics.spacingSm

                Rectangle {
                    width: parent.width - generalToggle.implicitWidth - Metrics.spacingSm
                    height: addField.implicitHeight + Metrics.spacingXs * 2
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.foreground

                    TextInput {
                        id: addField
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingXs
                        color: Theme.foreground
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeRegular
                        clip: true

                        Text {
                            anchors.fill: parent
                            visible: addField.text.length === 0
                            text: "Add task…"
                            color: Theme.foreground
                            opacity: 0.5
                            font.family: Metrics.fontFamily
                            font.pixelSize: Metrics.fontSizeRegular
                        }

                        // Return is dual-purpose, same overload Picker.qml
                        // gives Enter (always "activate the current
                        // thing") — typing something submits it as a new
                        // task; an empty field instead completes whichever
                        // row is keyboard-selected below.
                        Keys.onReturnPressed: {
                            if (addField.text.length > 0) {
                                TodoService.addTask(addField.text, { general: generalToggle.checked })
                                addField.text = ""
                                return
                            }
                            var row = root.rows[root.currentIndex]
                            if (row && row.kind === "task")
                                TodoService.completeTask(row.task.uuid)
                        }

                        Keys.onEscapePressed: Popups.todoPanelOpen = false
                        Keys.onUpPressed: root.moveSelection(-1)
                        Keys.onDownPressed: root.moveSelection(1)

                        // Tab toggles which section a new task lands in —
                        // the keyboard path for generalToggle's own tap
                        // handler. Needs explicit event.accepted, or Tab's
                        // default focus-traversal would pull keyboard
                        // focus off addField (there's nothing else in this
                        // panel that should ever hold it).
                        Keys.onPressed: function (event) {
                            if (event.key === Qt.Key_Tab) {
                                generalToggle.checked = !generalToggle.checked
                                event.accepted = true
                            }
                        }
                    }
                }

                // Tap to choose which section a new task lands in —
                // defaults to the active project, matching what's visually
                // first in the list below.
                Text {
                    id: generalToggle
                    property bool checked: false
                    text: checked ? "general" : "project"
                    color: Theme.accent
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall

                    TapHandler { onTapped: generalToggle.checked = !generalToggle.checked }
                }
            }
        }

        ListView {
            anchors.top: header.bottom
            anchors.topMargin: Metrics.spacingSm
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Metrics.spacingMd
            clip: true
            spacing: Metrics.spacingSm
            model: root.rows
            currentIndex: root.currentIndex

            // A single Item delegate that shows one of two branches rather
            // than a Loader switching between two Components — a Loader's
            // loaded item resolves unqualified property names against the
            // Component's own declaration scope, not the Loader instance
            // that created it, so a per-row `rowData` property set on the
            // Loader would silently be invisible inside the loaded item.
            delegate: Item {
                id: rowItem
                // Re-declared for the same reason NotificationCenter.qml's
                // delegate does: nested inside shell.qml's per-screen
                // `Scope { required property var modelData }`, which
                // shadows a ListView's own implicit modelData otherwise.
                required property var modelData
                // Once a delegate declares any required property, Qt
                // Quick stops implicitly injecting the other model
                // roles (like `index`) as ordinary context properties —
                // it has to be declared required too, or reading it here
                // would be a run-time error rather than just working the
                // way Picker.qml's plain, non-required delegate can.
                required property int index

                width: ListView.view.width
                // Item, unlike Text/Rectangle, doesn't default `height` to
                // `implicitHeight` — ListView needs the real property set
                // explicitly or every row collapses to zero height.
                height: modelData.kind === "header" ? headerText.implicitHeight : taskRow.implicitHeight

                // Keyboard-selection highlight — only ever true for a
                // "task" row, since currentIndex is never allowed to land
                // on a header (see root.taskRowIndices/onRowsChanged).
                Rectangle {
                    anchors.fill: parent
                    visible: rowItem.index === root.currentIndex
                    color: Theme.accent
                    opacity: 0.15
                }

                Text {
                    id: headerText
                    visible: rowItem.modelData.kind === "header"
                    text: rowItem.modelData.kind === "header" ? rowItem.modelData.text : ""
                    color: Theme.accent
                    opacity: 0.8
                    font.family: Metrics.fontFamily
                    font.pixelSize: Metrics.fontSizeSmall
                }

                Row {
                    id: taskRow
                    visible: rowItem.modelData.kind === "task"
                    spacing: Metrics.spacingSm

                    Text {
                        text: "[ ]"
                        color: Theme.foreground
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeRegular

                        TapHandler {
                            enabled: rowItem.modelData.kind === "task"
                            onTapped: TodoService.completeTask(rowItem.modelData.task.uuid)
                        }
                    }

                    Text {
                        width: rowItem.width - 24 - Metrics.spacingSm
                        text: rowItem.modelData.kind === "task"
                            ? rowItem.modelData.task.description + (rowItem.modelData.task.due ? "  (" + rowItem.modelData.task.due + ")" : "")
                            : ""
                        color: Theme.foreground
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeRegular
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}

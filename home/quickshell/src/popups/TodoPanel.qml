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
            // openAnim/closeAnim are two independent Animation objects
            // now (not one Behavior, which would retarget a still-running
            // transition automatically) -- stop() the other one first so
            // rapid toggling can't leave both driving panel.x at once.
            if (root.openFlag) {
                TodoService.refresh()
                addField.forceActiveFocus()
                closeAnim.stop()
                panel.beginOpen()
            } else {
                openAnim.stop()
                pendingOpen.enabled = false
                closeAnim.restart()
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

        readonly property int restX: parent.width - width  // resting position, panel open
        readonly property int hiddenX: parent.width         // fully offscreen, panel closed

        // Driven entirely by openAnim/closeAnim below, not a live binding
        // + Behavior — the first attempt at this relied on a Behavior
        // auto-inferring target/property for NumberAnimations nested
        // inside a SequentialAnimation, which doesn't reliably happen:
        // live testing showed the panel flying to x=0 (the screen's true
        // left edge) every time, exactly the "a missing/undefined value
        // becomes NaN, and Qt coerces NaN to 0" failure shape
        // Metrics.qml's own animDuration comment already documents for a
        // different property. Explicit target/property on every
        // animation below removes that inference entirely rather than
        // trying to get the implicit version right a second time.
        x: hiddenX

        // Two linear segments, not one eased curve — see
        // Metrics.settleOvershoot's own comment for why. Only the open
        // path overshoots; closing has nothing to "lock into," it just
        // slides off toward hiddenX in one stage.
        //
        // VERIFY: fixed against a concrete reported bug (see above), but
        // still not visually confirmed live — no Quickshell runtime in
        // the environment this was written in. Rebuild and check the
        // feel again, not just that it no longer flies to the left.
        SequentialAnimation {
            id: openAnim
            // On the outer SequentialAnimation, not the nested second
            // NumberAnimation — after the target/property inference bug
            // above, nested-animation signal semantics aren't something
            // to lean on a second time without being sure; the outer
            // animation's own finished() is unambiguous regardless.
            onFinished: panel.flashBorder()
            NumberAnimation {
                target: panel; property: "x"
                to: panel.restX - Metrics.settleOvershoot
                duration: Metrics.animDuration
                easing.type: Easing.Linear
            }
            NumberAnimation {
                target: panel; property: "x"
                to: panel.restX
                duration: Metrics.settleDuration
                easing.type: Easing.Linear
            }
        }

        NumberAnimation {
            id: closeAnim
            target: panel; property: "x"
            to: panel.hiddenX
            duration: Metrics.animDuration
            easing.type: Easing.Linear
        }

        // Root cause of the "appears from the left" bug reported live on
        // the very first open of any popup in this shell (not specific
        // to this file -- NotificationCenter's older single-stage
        // Behavior does the same thing, just self-heals less visibly):
        // AnimatedPopup's PanelWindow starts with visible: false and
        // likely isn't mapped by the compositor -- and so doesn't have
        // real width/height -- until openFlag first flips true, which is
        // exactly when this panel also tries to read parent.width to
        // compute where "off the right edge" even is. Every open after
        // the first is fine because by then the window has already been
        // mapped once for real.
        //
        // Rather than guess how long that race takes (a Qt.callLater()
        // is not a guaranteed-long-enough wait -- Wayland's configure
        // round-trip is compositor timing, not local event-loop timing),
        // this waits for the real value: openAnim only ever runs once
        // parent.width has actually reached a sane size. If parent.width
        // was already valid immediately (i.e. this theory turns out
        // wrong), the fast path fires with zero behavior change -- the
        // fallback below never engages.
        function beginOpen() {
            if (parent.width >= width) {
                openAnim.restart()
            } else {
                pendingOpen.enabled = true
            }
        }

        Connections {
            id: pendingOpen
            target: panel.parent
            enabled: false
            function onWidthChanged() {
                // root.openFlag re-checked here, not just at the top of
                // beginOpen() -- the panel could have been closed again
                // in the gap while this was still waiting on a real
                // width, and firing an open animation after the fact
                // would be wrong.
                if (root.openFlag && panel.parent.width >= panel.width) {
                    pendingOpen.enabled = false
                    openAnim.restart()
                }
            }
        }

        // Plain (non-bound) property, not `readonly ... : Theme.foreground`
        // — flashBorder() below needs to imperatively drive it through
        // Theme.accent and back. Left sitting at Theme.foreground once
        // the flash finishes, not a live binding, so a theme swap while
        // this panel happens to be open and idle would lag until the
        // next open/close — re-syncs every time it opens, which is the
        // only point that actually matters in practice.
        property color borderColor: Theme.foreground

        // Fired once the settle above lands (opening only) — a brief
        // pulse toward Theme.accent and back, so arriving reads as
        // something actuating/locking into place rather than an object
        // silently coming to rest. Onset is an instant snap (not eased
        // in), only the decay is animated — Theme.accent (#88c0d0) and
        // Theme.foreground (#d8dee9) are both fairly pale colors in this
        // theme, and easing into the peak on a 1px stroke diluted it
        // below the point of being noticeable at all. A hard cut into
        // the flash and a soft fade out of it reads as an actuation, not
        // a wobble either direction.
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

        SeamPanelShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: panel.borderColor
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

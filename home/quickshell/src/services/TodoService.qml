pragma Singleton
import QtQuick
import Quickshell.Io

// Data singleton for popups/TodoPanel.qml, same role NotificationService
// plays for NotificationCenter — except this one is pull-based (a Process
// run on demand) rather than push-based (a long-lived DBus server), since
// Taskwarrior has no "subscribe to changes" concept. TodoPanel calls
// refresh() itself in onVisibleChanged (same spot Picker.qml re-runs
// menuFetchProc/contextListProc every open), so switching the active
// project via syland-context and then opening this panel always shows the
// new project's tasks rather than a stale snapshot.
QtObject {
    id: root

    property var contextTasks: []
    property var generalTasks: []
    // Empty string when no project is active — mirrors syland-context's
    // own "no active project" state rather than inventing a second one.
    property string currentProject: ""

    function refresh() {
        listProc.running = true
    }

    function addTask(description, options) {
        var args = ["add", description]
        if (options && options.general) args.push("--general")
        if (options && options.recur) { args.push("--recur"); args.push(options.recur) }
        if (options && options.due) { args.push("--due"); args.push(options.due) }
        addProc.command = ["syland-todo"].concat(args)
        addProc.running = true
    }

    function completeTask(uuid) {
        completeProc.command = ["syland-todo", "done", uuid]
        completeProc.running = true
    }

    property Process listProc: Process {
        command: ["syland-todo", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n").filter(function (l) { return l.length > 0 })
                var rows = lines.map(function (l) { return JSON.parse(l) })
                var header = rows.find(function (r) { return r.scope === "context-header" })
                root.currentProject = header ? header.project : ""
                root.contextTasks = rows.filter(function (r) { return r.scope === "context" })
                root.generalTasks = rows.filter(function (r) { return r.scope === "general" })
            }
        }
    }

    // Fire-and-forget, command set imperatively right before each run —
    // same shape as Picker.qml's runProc/setContextProc. VERIFY: `onExited`
    // is Quickshell.Io.Process's standard exited(exitCode, exitStatus)
    // signal, but nothing in this repo exercises it yet and there's no
    // `task`/`syland-todo` binary in this sandbox to confirm against live.
    property Process addProc: Process {
        onExited: root.refresh()
    }

    property Process completeProc: Process {
        onExited: root.refresh()
    }
}

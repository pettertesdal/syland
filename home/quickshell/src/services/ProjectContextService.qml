pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live view of syland-context's own state file -- the active project set
// via `syland-context set <repo_path>` (home/syland-context.nix), read
// directly rather than shelled out to, since it's a small static file
// syland-context already maintains as its one source of truth, not a
// script with real logic to run. Same FileView/watchChanges/reload()
// pattern theme/ColorLoader.qml already uses for the identical class of
// problem ("watch an external file, re-parse on change").
QtObject {
    id: root

    // "" means no project is currently set (state.json missing, empty,
    // or unparseable) -- windows/StatsModule.qml's own TextMeter slot
    // already treats an empty value as "nothing to show" for free.
    property string projectName: ""

    property FileView fileView: FileView {
        id: fileView

        path: Quickshell.env("HOME") + "/.config/syland/context/state.json"
        watchChanges: true

        // watchChanges alone only fires fileChanged(), it doesn't re-read
        // text() on its own -- same quirk ColorLoader.qml's own fileView
        // already documents and works around.
        onFileChanged: reload()

        onTextChanged: {
            var t = text().trim()
            if (t.length === 0) {
                root.projectName = ""
                return
            }
            try {
                var state = JSON.parse(t)
                root.projectName = state.name || ""
            } catch (e) {
                console.warn("[ProjectContextService] couldn't parse", fileView.path, e)
                root.projectName = ""
            }
        }
    }
}

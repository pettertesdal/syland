import QtQuick
import Quickshell
import Quickshell.Io

// Not a singleton — Theme.qml owns exactly one instance of this as an
// implementation detail (declared as `property ColorLoader _loader:` over
// there). Everything else in the shell should go through Theme, never
// reach into this file directly.
//
// This is where the "how do colors get here" mechanism lives:
//   1. On startup, run `syland-theme-apply quickshell`, which regenerates
//      ~/.config/syland/themes/quickshell.generated from colors.toml.
//      This means you never have to remember to run it by hand after
//      editing colors.toml — the shell does it every time it starts.
//   2. Watch that generated file with a FileView (watchChanges: true).
//      watchChanges only fires fileChanged() when the file changes on
//      disk — it does NOT re-read the content on its own, so the
//      fileView below explicitly calls reload() in response (confirmed
//      live: without this, colors stayed stale after syland-theme-apply
//      ran until quickshell was killed and relaunched). reload() updates
//      text(), which fires onTextChanged, which is what actually updates
//      every property bound to these colors.
QtObject {
    id: root

    // Fallback values so the bar has sane colors before the generated
    // file exists, or if parsing ever fails. Copied from
    // dot_config/syland/themes/colors.toml — keep these two in sync.
    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property color accent: "#89b4fa"
    property color red: "#f38ba8"
    property color green: "#a6e3a1"
    property color yellow: "#f9e2af"

    Component.onCompleted: renderOnce.running = true

    // Unlike Item, QtObject has no default property to hold implicit
    // children — Process/FileView need an explicit property to attach to
    // (a bare `Process { ... }` block fails to load).
    property Process renderOnce: Process {
        command: ["syland-theme-apply", "quickshell"]
    }

    property FileView fileView: FileView {
        id: fileView

        path: Quickshell.env("HOME") + "/.config/syland/themes/quickshell.generated"
        watchChanges: true

        // watchChanges alone only fires fileChanged() — it does NOT
        // re-read the file into text()/data() on its own (confirmed
        // against Quickshell.Io's own qmltypes: fileChanged is a signal
        // distinct from textChanged/dataChanged, and FileView exposes a
        // separate reload() method). Without this handler, an external
        // rewrite of the file (exactly what syland-theme-apply does)
        // updates the file on disk but onTextChanged below never fires —
        // confirmed live: colors stayed stale after `syland-theme-apply
        // apply <theme>` until quickshell was killed and relaunched.
        onFileChanged: reload()

        // syland-theme-apply always prepends a "# managed by syland ..."
        // comment line before the JSON payload (see
        // executable_syland-theme-apply and theme-renderers/executable_quickshell).
        // Strip any leading '#' lines the same way syland-menu strips '//'
        // comments from menu.jsonc, then parse whatever's left.
        //
        // Quirk worth knowing: despite the signal being named
        // `textChanged`, `text` itself is a *function* on this Quickshell
        // version's FileView (`text(): string`), not a plain property —
        // written this way so reading it doesn't eagerly trigger a load.
        // You have to call `text()`, not read `text`; referencing the bare
        // function object and calling `.split()` on it throws.
        onTextChanged: {
            var jsonLines = text().split("\n").filter(function (line) {
                var t = line.trim()
                return t.length > 0 && t[0] !== "#"
            })
            if (jsonLines.length === 0)
                return

            try {
                var colors = JSON.parse(jsonLines.join("\n"))
                if (colors.background !== undefined) root.background = colors.background
                if (colors.foreground !== undefined) root.foreground = colors.foreground
                if (colors.accent !== undefined) root.accent = colors.accent
                if (colors.red !== undefined) root.red = colors.red
                if (colors.green !== undefined) root.green = colors.green
                if (colors.yellow !== undefined) root.yellow = colors.yellow
            } catch (e) {
                console.warn("[ColorLoader] couldn't parse", fileView.path, e)
            }
        }
    }
}

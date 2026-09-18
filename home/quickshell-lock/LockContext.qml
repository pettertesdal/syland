import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Auth logic, split from the visual (LockSurface.qml) — ported near-
// verbatim from the official quickshell-examples/lockscreen/LockContext.qml,
// pointed at config/lock.nix's own declared PAM service (syland-lock)
// instead of a hand-rolled pam.d file. configDirectory is left at its
// default (/etc/pam.d) since NixOS generates the real file there from
// that Nix declaration — nothing to bundle alongside this QML.
Scope {
    id: root

    signal unlocked()
    signal failed()

    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false

    onCurrentTextChanged: showFailure = false

    function tryUnlock() {
        if (currentText === "")
            return
        root.unlockInProgress = true
        pam.start()
    }

    // Hands the retreat animation off to the main shell's own
    // windows/LockRetreatOverlay.qml the instant auth succeeds — see
    // that file's own comment for why the retreat can't play on this
    // process's own lock surface. Fire-and-forget on purpose: `qs ipc
    // call` targets the "default" config (the main shell) with no
    // instance-selection flags needed, since this process's own config
    // is named "quickshell-lock", not "default" — but if the main shell
    // isn't even running, this command just fails/exits quickly, and
    // nothing here waits on it or checks its result. The real unlock
    // (shell.qml's own onUnlocked) always proceeds regardless — a
    // missing animation is fine, a lock that won't open because a
    // helper command failed is not.
    //
    // Logged rather than silent: confirmed live that the identical `qs
    // ipc call lock-retreat trigger` command works perfectly run
    // standalone, but never actually fires during a real unlock — the
    // leading theory is that `running = true` only *schedules* the spawn
    // (QProcess::start() is async, it doesn't fork in the same call),
    // and unlockDelay below used to not exist, so root.unlocked() (which
    // shell.qml turns straight into Qt.quit()) could tear this whole
    // process down before the event loop ever got a tick to actually
    // start the child. These logs are how to tell, next time, whether
    // that theory was right or whether it's something else entirely.
    property Process retreatTrigger: Process {
        command: ["qs", "ipc", "call", "lock-retreat", "trigger"]
        onStarted: console.log("[lock] retreatTrigger started")
        onExited: function (exitCode, exitStatus) {
            console.log("[lock] retreatTrigger exited code=" + exitCode + " status=" + exitStatus)
        }
    }

    // 80ms between firing the trigger and actually signaling unlocked()
    // (see retreatTrigger's own comment) — comfortably more than the
    // roundtrip that command actually takes (confirmed near-instant
    // manually), with no perceptible added delay to unlocking.
    property Timer unlockDelay: Timer {
        interval: 80
        onTriggered: root.unlocked()
    }

    PamContext {
        id: pam
        config: "syland-lock"

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText)
        }

        onCompleted: function (result) {
            if (result === PamResult.Success) {
                console.log("[lock] auth succeeded, firing retreatTrigger")
                retreatTrigger.running = true
                unlockDelay.start()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failed()
            }
            root.unlockInProgress = false
        }
    }
}

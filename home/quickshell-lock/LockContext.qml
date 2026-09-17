import QtQuick
import Quickshell
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

    PamContext {
        id: pam
        config: "syland-lock"

        onPamMessage: {
            if (this.responseRequired)
                this.respond(root.currentText)
        }

        onCompleted: function (result) {
            if (result === PamResult.Success) {
                root.unlocked()
            } else {
                root.currentText = ""
                root.showFailure = true
                root.failed()
            }
            root.unlockInProgress = false
        }
    }
}

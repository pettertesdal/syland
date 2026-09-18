import Quickshell
import Quickshell.Wayland

// Standalone lock config — deliberately not part of home/quickshell/shell.qml
// (see home/syland-lock.nix's own comment for why: this has to keep
// working even if the main shell's own process crashes). Ported
// near-verbatim from the official quickshell-examples/lockscreen/shell.qml.
// WlSessionLock spawns one WlSessionLockSurface per monitor automatically
// while locked; unlocking (LockContext's own unlocked() signal) flips
// locked back to false and quits immediately — per WlSessionLock's own
// documented behavior, a conformant compositor leaves the screen locked
// and blanked if this process dies or exits without doing that, which is
// the actual security guarantee, not something to work around.
//
// No triggering of any kind happens here — LockSurface.qml's own
// entranceCheck/readyTrigger (fired from its Component.onCompleted)
// handle both ends of the lock-side animation handoff, and
// LockContext.qml's own retreatTrigger handles the unlock side. This
// file just declares the lock itself.
ShellRoot {
    LockContext {
        id: lockContext
        onUnlocked: {
            lock.locked = false
            Qt.quit()
        }
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}

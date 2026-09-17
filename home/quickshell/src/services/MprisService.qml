pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

// Owns the shell's one view into MPRIS players — same eager-singleton
// reasoning as services/NotificationService.qml. Quickshell's own
// Quickshell.Services.Mpris.Mpris singleton already tracks every player
// on the bus; this just picks one to actually show, since there's one
// music widget (windows/MusicModule.qml, two instances flanking the
// clock), not one per player.
QtObject {
    id: root

    // Whichever player is currently playing, or — if nothing is —
    // whichever player exists at all, so a paused player's title/art
    // keeps showing instead of the widget going blank the instant you
    // hit pause. null when no MPRIS player exists.
    readonly property var activePlayer: {
        var players = Mpris.players.values
        for (var i = 0; i < players.length; i++)
            if (players[i].isPlaying) return players[i]
        return players.length > 0 ? players[0] : null
    }

    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
}

import QtQuick
import "../"

// Text label, not an icon glyph, on purpose: fc-query showed
// ProggyCleanNerdFontMono-Regular.ttf's glyph coverage is narrower than a
// full Nerd Fonts build, and the classic documented wifi codepoint isn't
// safely assumed present without checking. Swap in a verified glyph later
// — see Metrics.fontFamily's own comment.
Row {
    spacing: Metrics.spacingXs

    Text {
        text: "NET"
        color: NetworkStatusService.connected ? Theme.foreground : Theme.red
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }

    Text {
        visible: NetworkStatusService.connected
        text: Math.round(NetworkStatusService.signalStrength) + "%"
        color: Theme.foreground
        font.family: Metrics.fontFamily
        font.pixelSize: Metrics.fontSizeSmall
    }
}

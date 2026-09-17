import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../shapes"

// The two music modules flanking windows/CenterModule.qml's clock — one
// file handles both, mirrored via `align` (matches
// Syland-music_left_with_cassett-widget-form.png /
// Syland-music_right-widget-form.png). Doesn't reuse
// components/HangingModule.qml: that hardcodes one shared
// shapes/HangingBoxShape.qml internally (not swappable), and these need
// a different shape entirely (shapes/MusicModuleShape.qml) plus an extra
// slide-in "cassette" element the shared component has no concept of —
// same reasoning popups/BluetoothPanel.qml's own bespoke shape/behavior
// already diverged from HangingModule for.
PanelWindow {
    id: root

    property string align: "left" // "left" | "right"
    // The clock's own HangingModule instance, so this can sit flush
    // against its actual on-screen position — a separate wlr-layer-shell
    // window with its own independent geometry, not something a plain
    // anchor/alignment on this window alone could reach. Same pattern
    // popups/BluetoothPanel.qml's own `rightModule` property uses.
    // Passed in from shell.qml.
    property var centerModule: null

    readonly property int barCount: CavaService.barCount
    readonly property int barWidth: 12
    readonly property int barSpacing: 2
    readonly property int visualizerWidth: barCount * barWidth + (barCount - 1) * barSpacing

    // The module is split by a vertical divider into two sections: the
    // inner one (toward the clock) always holds the visualizer; the
    // outer one (away from the clock) holds different content per
    // side — left shows a scrolling track-title marquee, right shows
    // the system volume. See box's own children below for which is
    // which.
    readonly property int outerWidth: 90
    readonly property int contentPadding: Metrics.spacingMd
    readonly property int dividerGap: Metrics.spacingSm
    readonly property int dividerWidth: 1
    // Margin between the visualizer's own inner-facing edge (the side
    // toward the clock, opposite the divider) and box's own edge there —
    // separate from contentPadding (which only governs the outer
    // section's own margin) so this can be tuned independently.
    readonly property int barsInnerMargin: Metrics.spacingLg
    readonly property int boxWidth: contentPadding + outerWidth + dividerGap * 2 + dividerWidth + visualizerWidth + barsInnerMargin

    // Only the left module gets the cassette (see the mockup — it's only
    // in the "_with_cassett" variant), and it's purely decorative: no
    // interaction, no data beyond MprisService.isPlaying.
    readonly property bool showCassette: align === "left"
    readonly property int cassetteWidth: 40
    readonly property int cassetteHeight: 18
    readonly property int cassetteGap: Metrics.spacingXs
    // How far the cassette tucks up *underneath* box's own bottom edge
    // at rest — box is declared after (rendered on top of) cassette
    // specifically so this overlap reads as the cassette being inserted
    // into the panel, not just parked below it with a gap. Deeper than
    // the first pass (6px) — confirmed live that read as barely tucked
    // in at all.
    readonly property int cassetteOverlap: 12

    anchors { top: true; left: true; right: true }
    // Sized for the cassette's *hidden* extent, not just its resting
    // position (same reasoning components/HangingModule.qml's own
    // implicitHeight comment gives for grownHeight) — it needs a full
    // cassetteHeight of travel room below its resting spot to actually
    // read as sliding up into place, not just the small few-px shift an
    // earlier version used (confirmed live: too subtle to notice at all,
    // read as a plain fade instead of a slide).
    implicitHeight: Metrics.moduleHeight + (showCassette ? cassetteGap + cassetteHeight * 2 : 0)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    // Scoped to box only — cassette is purely decorative and never needs
    // to intercept input, so it's deliberately left out rather than
    // widening the mask to cover it too.
    mask: Region { item: box }

    // The "cassette" — a small decorative shape (rectangle + two reels,
    // matching the mockup) that slides up into place under the left
    // module the moment music starts, reversing when it stops. Declared
    // *before* box (below, rendered on top of this) so the resting
    // position's overlap with box's own bottom edge reads as the
    // cassette sliding into the panel, not just appearing below it.
    // Travel is cassetteGap + cassetteHeight + cassetteOverlap end to
    // end — confirmed live that a small few-px nudge reads as a plain
    // fade, not an actual slide.
    Item {
        id: cassette
        visible: root.showCassette
        width: root.cassetteWidth
        height: root.cassetteHeight
        // Aligned with outerSection (the title display), not centered on
        // the whole box — reads as inserting into the same slot the
        // title scrolls in, not just somewhere under the module in
        // general. outerSection is declared later in the file (inside
        // box), but QML ids resolve regardless of declaration order.
        x: box.x + outerSection.x + (outerSection.width - width) / 2
        y: MprisService.isPlaying
            ? box.height - root.cassetteOverlap
            : box.height + root.cassetteGap + root.cassetteHeight
        opacity: MprisService.isPlaying ? 1 : 0

        Behavior on y { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }
        Behavior on opacity { NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear } }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.width: 1
            border.color: Theme.foreground
            radius: 0

            Row {
                anchors.centerIn: parent
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.foreground
                }
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.foreground
                }
            }
        }
    }

    Item {
        id: box
        width: root.boxWidth
        height: Metrics.moduleContentHeight
        y: 0
        x: root.centerModule
            ? (root.align === "left"
                ? root.centerModule.boxX - width - Metrics.centerGap
                : root.centerModule.boxX + root.centerModule.boxWidth + Metrics.centerGap)
            : 0

        MusicModuleShape {
            anchors.fill: parent
            fillColor: Theme.background
            strokeColor: Theme.foreground
            align: root.align
        }

        // Outer section: left-of-box for align="left" (outer/screen-edge
        // side there), right-of-box for align="right" — same "outer"
        // concept shapes/MusicModuleShape.qml's own align property uses.
        Item {
            id: outerSection
            width: root.outerWidth
            height: parent.height
            y: 0
            x: root.align === "left"
                ? root.contentPadding
                : parent.width - root.contentPadding - width
            clip: true

            // An old cassette-deck-style readout — a small recessed
            // "screen" bezel, always present on both sides (even idle,
            // like a deck's display is dark but still there when
            // stopped) — sized to just fit one line of text rather than
            // filling the whole outer section, so it reads as a little
            // LCD window instead of a big panel.
            Rectangle {
                id: displayBezel
                anchors.centerIn: parent
                width: parent.width - Metrics.spacingSm * 2
                // Was Metrics.fontSizeRegular (16) — the text inside
                // actually renders at fontSizeSmall (11), so that was
                // sizing the bezel for a font size nothing here uses,
                // and didn't even fit inside box's own 22px height in
                // the first place.
                height: Metrics.fontSizeSmall + Metrics.spacingXs
                // Same accent color the visualizer bars use, no border —
                // a solid lit-up panel rather than an outlined dark
                // recess. Text sits on top in Theme.background instead
                // of the other way around.
                color: Theme.accent
                radius: 0
            }

            // Scrolling track-title marquee, clipped to displayBezel's
            // own bounds (not the wider outerSection) so the scroll
            // reads as text moving *through a small window*, matching
            // the bezel's own visual size. Nothing shows at all unless
            // MprisService.isPlaying — a paused/stopped player still has
            // a trackTitle, but the display should read as off, not
            // frozen on stale text.
            Item {
                id: marqueeViewport
                visible: root.align === "left" && MprisService.isPlaying
                x: displayBezel.x
                y: displayBezel.y
                width: displayBezel.width
                height: displayBezel.height
                clip: true

                Row {
                    id: marqueeRow
                    y: (marqueeViewport.height - height) / 2
                    spacing: 24

                    Text {
                        id: titleText
                        text: MprisService.activePlayer ? MprisService.activePlayer.trackTitle : ""
                        color: Theme.background
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeSmall
                        font.letterSpacing: 1
                    }

                    // Second copy, spacing px after the first — scrolling
                    // by exactly titleText.implicitWidth + spacing lands
                    // this copy exactly where the first one started, so
                    // looping the animation back to x:0 reads as
                    // seamless instead of jumping.
                    Text {
                        text: titleText.text
                        color: Theme.background
                        font.family: Metrics.fontFamily
                        font.pixelSize: Metrics.fontSizeSmall
                        font.letterSpacing: 1
                    }
                }

                // Always scrolling while visible, not gated on the text
                // actually overflowing — confirmed live that the
                // fits-so-don't-bother condition this had before was
                // reading as "title isn't scrolling" at all for shorter
                // titles; a cassette-deck ticker reads as continuously
                // moving regardless of length anyway.
                NumberAnimation {
                    id: marqueeAnim
                    target: marqueeRow
                    property: "x"
                    from: 0
                    to: -(titleText.implicitWidth + marqueeRow.spacing)
                    duration: Math.max(3000, titleText.implicitWidth * 40)
                    loops: Animation.Infinite
                    running: marqueeViewport.visible
                }
            }

            // Right: system output volume (services/VolumeService.qml —
            // the actual speaker level, not any one MPRIS player's own
            // volume, which is unreliably supported across players).
            Text {
                visible: root.align === "right"
                anchors.centerIn: parent
                text: "Vol: " + (VolumeService.muted ? "mute" : Math.round(VolumeService.volume * 100) + "%")
                color: Theme.background
                font.family: Metrics.fontFamily
                font.pixelSize: Metrics.fontSizeSmall
                font.letterSpacing: 1
            }
        }

        Rectangle {
            id: divider
            width: root.dividerWidth
            height: parent.height
            y: 0
            x: root.align === "left"
                ? outerSection.x + outerSection.width + root.dividerGap
                : outerSection.x - root.dividerGap - width
            color: Theme.foreground
        }

        Row {
            // Bottom-anchored to box's own fixed edge, not centerIn —
            // Row sizes itself to its tallest current child, so
            // centerIn made the *whole row* (and therefore every bar's
            // own anchors.bottom: parent.bottom, which is this row's
            // bottom) drift up and down as the loudest bar's height
            // changed, instead of each bar just growing upward from one
            // fixed baseline. Confirmed live: this is exactly what read
            // as "quickshell compensates to push it down so the
            // midpoint stays centered."
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Metrics.spacingSm
            x: root.align === "left"
                ? divider.x + divider.width + root.dividerGap
                : root.barsInnerMargin
            spacing: root.barSpacing

            Repeater {
                model: root.barCount

                delegate: Rectangle {
                    required property int index
                    width: root.barWidth
                    // cava's own scale is 0-100; clamped to a visible
                    // minimum so idle/silent bars read as present rather
                    // than vanishing to a 0-height sliver.
                    height: Math.max(2, (CavaService.bars[index] / 100) * (Metrics.moduleHeight - Metrics.spacingSm * 2))
                    anchors.bottom: parent.bottom
                    color: Theme.accent

                    Behavior on height {
                        NumberAnimation { duration: Metrics.animDuration; easing.type: Easing.Linear }
                    }
                }
            }
        }
    }
}

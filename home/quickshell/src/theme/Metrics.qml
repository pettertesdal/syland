pragma Singleton
import QtQuick

// Non-color design tokens, split out of Theme.qml now that there are
// enough of them to justify it — Theme.qml's own comment already flagged
// this split as deferred until that point. Sizing/spacing constants and
// the shared animation duration used by every popup (see
// components/AnimatedPopup.qml), plus a small typography scale so new
// components stop inventing their own ad hoc pixelSize values.
//
// Terminal-minimal direction: cornerRadius is 0 (straight lines, no
// curves — see windows/Border.qml, which used to carve a curve with a
// Canvas and now doesn't), animDuration is fast and every Behavior using
// it should ease linearly rather than ease in/out, and fontFamily is
// ProggyClean (nerd-fonts.proggy-clean-tt in configuration.nix). Verified
// via `fc-scan` against the built package in the Nix store: the family
// name is "ProggyClean Nerd Font Mono" specifically — the "Mono" variant,
// not the plain/Propo/SZ/CE variants the same package also ships, which
// aren't fixed-width. Won't actually render as Proggy Clean until the
// font is deployed (nixos-rebuild switch) — it'll fall through to
// whatever fontconfig picks as a substitute until then.
QtObject {
    // Renamed from barHeight — there's no more full-width bar, just three
    // separate hanging modules (see components/HangingModule.qml), but
    // they still share one consistent height.
    property int moduleHeight: 32
    property int borderWidth: 1
    property int cornerRadius: 0
    // How deep the diagonal cut is on a HangingModule's bottom corners.
    property int chamferSize: 10

    // How far LeftModule/RightModule sit from the screen's left/right edge.
    // Not arbitrary: chosen so each module's outer diagonal, extended,
    // points exactly at the screen's physical corner — derived, not
    // guessed. popups/NotificationCenter.qml's own top-right notch shares
    // this same margin, which is what makes its seam with RightModule land
    // on the exact same line rather than merely a visually-close one.
    readonly property int moduleMargin: moduleHeight - chamferSize

    // windows/MusicModule.qml's own box height (shorter than
    // moduleHeight — its shape has no chamfer to clear, but was tuned
    // shorter anyway). popups/Picker.qml's outerEdgeDrop and
    // windows/CenterModule.qml's own travel distance both key off this
    // same number now too, so all three stay in lockstep rather than
    // three independently-hardcoded copies drifting apart.
    property int moduleContentHeight: moduleHeight - 10

    // Gap on either side of windows/CenterModule.qml's own box that
    // windows/MusicModule.qml (both instances) and popups/Picker.qml all
    // key off of — Picker's own width is derived from this so it fits
    // snugly in the same gap the two music modules already leave, rather
    // than three independently-hardcoded numbers drifting apart.
    property int centerGap: 200

    // Shared duration for every Behavior/NumberAnimation in the shell —
    // missing this property doesn't fail loudly: `Metrics.animDuration`
    // silently evaluates to `undefined` wherever it's referenced,
    // `undefined + 20` (as in a Timer's `interval:`) becomes NaN, and QML
    // coerces that to 0 rather than erroring — which is exactly the bug
    // that shipped in ExamplePanel.qml before this property existed (see
    // components/AnimatedPopup.qml's closeTimer).
    property int animDuration: 120

    // Two-stage "slide + settle" motion (pilot: popups/TodoPanel.qml) —
    // an arriving panel slides settleOvershoot px past its resting
    // position, then snaps back over settleDuration. Two chained linear
    // NumberAnimations, not one eased curve (no Easing.OutBack): the
    // comment on animDuration above already commits this shell to linear
    // motion everywhere, and this keeps that true segment-by-segment
    // while still reading as something arriving and catching rather than
    // gliding to a stop.
    property int settleOvershoot: 6
    property int settleDuration: 45

    property string fontFamily: "ProggyClean Nerd Font Mono"
    property int fontSizeSmall: 11
    property int fontSizeRegular: 13
    property int fontSizeLarge: 16

    property int spacingXs: 4
    property int spacingSm: 8
    property int spacingMd: 12
    property int spacingLg: 20
}

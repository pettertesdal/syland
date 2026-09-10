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

    // Shared duration for every Behavior/NumberAnimation in the shell —
    // missing this property doesn't fail loudly: `Metrics.animDuration`
    // silently evaluates to `undefined` wherever it's referenced,
    // `undefined + 20` (as in a Timer's `interval:`) becomes NaN, and QML
    // coerces that to 0 rather than erroring — which is exactly the bug
    // that shipped in ExamplePanel.qml before this property existed (see
    // components/AnimatedPopup.qml's closeTimer).
    property int animDuration: 120

    property string fontFamily: "ProggyClean Nerd Font Mono"
    property int fontSizeSmall: 11
    property int fontSizeRegular: 13
    property int fontSizeLarge: 16

    property int spacingXs: 4
    property int spacingSm: 8
    property int spacingMd: 12
    property int spacingLg: 20
}

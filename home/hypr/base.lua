-- hl.env() must run before the display server initializes (per Hyprland's
-- own docs) so the value propagates to everything Hyprland subsequently
-- launches — including exec-once/hl.on("hyprland.start", ...) processes.
-- This is the actual fix for "qs works when I run it manually from a
-- terminal, but not on autostart after reboot": .zshrc's PATH export only
-- applies to interactive shells, never to autostart-launched processes.
--
-- If you use uwsm to launch Hyprland, put this in ~/.config/uwsm/env
-- instead (export PATH=...) — uwsm users are advised against setting
-- environment variables directly in hyprland.lua.
hl.env("PATH", os.getenv("HOME") .. "/.local/share/syland/bin:" .. (os.getenv("PATH") or ""))

-- Border colors come from syland-theme-apply, which writes this file and
-- then runs `hyprctl reload config-only` (the only live-reload primitive
-- that actually works here — `hyprctl keyword` errors with "can't work
-- with non-legacy parsers" on this Lua-config setup, confirmed live).
-- Loaded into the single hl.config() call below rather than a second call
-- from a separate file: unverified whether hl.config merges keys across
-- calls or replaces the whole `general` table, and a second call risks
-- silently wiping gaps_in/gaps_out/border_size.
local themeOk, theme = pcall(dofile, os.getenv("HOME") .. "/.config/syland/themes/hyprland.generated.lua")
if not themeOk then
    theme = { ["col.active_border"] = "rgba(89b4faff)", ["col.inactive_border"] = "rgba(313244ff)" }
end

-- CONFIRMED patterns (hl.config nested tables, hl.on autostart) — verified
-- against Hyprland's official example config and wiki as of this writing.
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 36,
        border_size = 1,
        ["col.active_border"] = theme["col.active_border"],
        ["col.inactive_border"] = theme["col.inactive_border"],
    },
    decoration = {
        rounding = 0,
	inactive_opacity = 0.7,
    },
    input = {
        kb_layout = "no",
        follow_mouse = 1,
    },
})

-- CONFIRMED: field is `output` (a string), not `name` — fixed after your
-- real error output. Run `hyprctl monitors` to get your actual output name
-- (e.g. "eDP-1") and use that instead of a wildcard once you know it —
-- explicit is safer than guessing at wildcard syntax.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
-- Matched by desc, not connector name -- DP-6/DP-7 are MST-assigned and
-- swap which physical monitor they refer to between reconnects.
-- Both externals capped (test): Hyprland's own log showed "failed to
-- commit: No space left on device" on the atomic DRM request -- real
-- MST link bandwidth exhaustion, not a mode/firmware issue. Capping
-- just the Odyssey wasn't enough on its own; cutting the ultrawide's
-- mode too to see if the combined budget then fits.
hl.monitor({ output = "desc:Samsung Electric Company LC27G7xT", mode = "2560x1440@60", position = "auto", scale = 1 })
hl.monitor({ output = "desc:Samsung Electric Company LC34G55T", mode = "preferred", position = "auto", scale = 1 })

hl.on("hyprland.start", function()
    -- Started here rather than via home-manager's services.awww systemd
    -- unit -- see home/wallpaper.nix for why that never actually fires
    -- on this system. Before qs/quickshell so the daemon is already up
    -- if anything ends up calling `awww img` early.
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("qs")
    hl.exec_cmd("mako")
    -- hypridle.service exists (home/hypridle.nix generates its config
    -- and unit file) but isn't auto-started -- same
    -- graphical-session.target-never-activates issue as awww above, see
    -- home/hypridle.nix's own comment. `systemctl --user start` on an
    -- already-running unit is a no-op, so this is safe to run every
    -- Hyprland start regardless of whether it's already up.
    hl.exec_cmd("systemctl --user start hypridle.service")
end)

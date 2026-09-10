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

-- CONFIRMED patterns (hl.config nested tables, hl.on autostart) — verified
-- against Hyprland's official example config and wiki as of this writing.
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 18,
        border_size = 1,
    },
    decoration = {
        rounding = 0,
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

hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    hl.exec_cmd("mako")
end)

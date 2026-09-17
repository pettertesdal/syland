local mainMod = "SUPER"
local terminal = "ghostty"

-- CONFIRMED patterns below (hl.bind + hl.dsp.exec_cmd/window.float/window.close
-- + submap) — verified against the Hyprland wiki's Binds page and official
-- example config. Lines marked VERIFY are best-effort and should be checked
-- against your installed version's hl.meta.lua stubs, or regenerated with
-- the community `hyprlang2lua` converter for a version-accurate conversion.

-- core
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
-- VERIFY: fullscreen dispatcher name
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

-- syland
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call syland-menu toggle"), { description = "Open menu" })
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("qs ipc call syland-menu keybinds"), { description = "Search keybinds" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("syland-context open project"), { description = "Open current project's dev terminal" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("syland-context open pdf"), { description = "Open context PDF" })
-- ALT + P freed up: syland-context's "notes" subcommand (per-project
-- TODO.md) is retired now that the Taskwarrior panel (SUPER + ALT + T)
-- is the one TODO system.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("syland-context open docs"), { description = "Open context docs (markdown/README)" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notification-center toggle"), { description = "Toggle notification center" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("qs ipc call bluetooth-panel toggle"), { description = "Toggle bluetooth panel" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call theme-switcher toggle"), { description = "Toggle theme switcher panel" })
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("syland-theme-apply toggle"), { description = "Toggle variation switch" })
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("qs ipc call todo-panel toggle"), { description = "Toggle TODO panel" })
-- Not SUPER + L / SUPER + SHIFT + L -- both already taken by the
-- vim-style hjkl focus/move block below. "safe to run every Hyprland
-- start" no-op reasoning from base.lua's own hl.on hook applies here
-- too -- starting an already-active syland-lock.service is a no-op, not
-- a second lock instance.
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("systemctl --user start syland-lock.service"), { description = "Lock screen" })

-- workspaces — VERIFY: exact workspace-switch/move dispatcher names
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = key}), { description = "Workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = key}), { description = "Move to workspace " .. i })
end

-- vim-style focus movement between windows (no shift) and window
-- movement within the layout (with shift, swaps position with the
-- neighbor in that direction). SUPER + SHIFT + Number (below) still moves
-- a window to a specific workspace -- numbers vs letters, no collision.
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus window left" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus window down" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus window up" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus window right" })

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })

-- monitors — resolved by physical position (l/r/u/d), not connector name,
-- so this stays correct even when the dock's MST enumeration reorders
-- DP-6/DP-7 between reconnects.
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.workspace.move({ monitor = "r" }), { description = "Move workspace to display on the right" })
hl.bind(mainMod .. " + SHIFT + LEFT", hl.dsp.workspace.move({ monitor = "l" }), { description = "Move workspace to display on the left" })

-- system
-- Example volume button that allows press and hold, volume limited to 150%
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })

-- Example volume button that will activate even while an input inhibitor is active
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true } )

-- Skip player on long press and only skip 5s on normal press
hl.bind("SUPER + XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { long_press = true })
hl.bind("SUPER + XF86AudioNext", hl.dsp.exec_cmd("playerctl position +5"))

-- focus mode (example submap — add more modes the same way)
hl.bind(mainMod .. " + F1", hl.dsp.submap("focus"), { description = "Enter focus mode" })
hl.define_submap("focus", function()
    hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit focus mode" })
end)

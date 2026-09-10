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
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("syland-context switch"), { description = "Switch context" })
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("syland-context open pdf"), { description = "Open context PDF" })
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("syland-context open notes"), { description = "Open context notes" })
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call example-panel toggle"), { description = "Toggle example panel" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notification-center toggle"), { description = "Toggle notification center" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("qs ipc call bluetooth-panel toggle"), { description = "Toggle bluetooth panel" })

-- workspaces — VERIFY: exact workspace-switch/move dispatcher names
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = key}), { description = "Workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = key}), { description = "Move to workspace " .. i })
end

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

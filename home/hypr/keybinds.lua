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
-- Opens the picker directly at the Context level (IpcManager.qml's
-- syland-menu context() function, alongside its existing toggle()).
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call syland-menu context"), { description = "Open project picker" })
-- SUPER + 0 would normally collide with the workspace loop below
-- (i % 10 maps workspace 10 to key "0") -- that loop's own focus-bind
-- for key 0 is skipped for exactly this reason; workspace 10 is still
-- reachable via SUPER + SHIFT + 0 (move a window there) or scrolling
-- workspaces, just not a direct focus keybind anymore.
-- A true toggle, unlike the old one-way-show SUPER+C: ensures the
-- devterm window is showing the current project's own zellij session
-- (closing/respawning it if it's showing a different project's,
-- creating fresh if no window exists at all), and hides the special
-- workspace if it's already open, correct, and visible.
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("syland-context toggle-devterm"), { description = "Toggle current project's dev terminal" })
-- Thunderbird runs the whole session on its own hidden special
-- workspace (home/hypr/base.lua's startup hook, home/hypr/layerrules.lua's
-- window rule). Through syland-mail-toggle, not a direct
-- toggle_special() dispatcher call -- that alone would just show/hide
-- an empty special workspace forever once the window's been closed,
-- confirmed live: closing Thunderbird then pressing this only revealed
-- an empty workspace, nothing relaunched it. The script relaunches it
-- first if it's not running, then toggles visibility.
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("syland-mail-toggle"), { description = "Toggle mail" })
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
-- vim-style hjkl focus/move block below. Plays the lock entrance
-- animation on the main shell (windows/LockAssemblyOverlay.qml) --
-- that overlay's own onFinished is what actually starts
-- syland-lock.service, once the animation itself finishes.
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("qs ipc call lock-assembly trigger"), { description = "Lock screen" })

-- workspaces — VERIFY: exact workspace-switch/move dispatcher names
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    -- key 0 (workspace 10) skips its own focus-bind -- SUPER + 0 is
    -- reserved for toggling the project dev terminal (above). Move-to
    -- (SHIFT + 0) is unaffected, workspace 10 stays reachable that way.
    if key ~= 0 then
        hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = key}), { description = "Workspace " .. i })
    end
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

hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("qs ipc call focus-mode toggle"), { description = "Toggle focus mode" })

hl.layer_rule({
	match = {namespace = "quickshell"},
	no_anim = true,
})
hl.window_rule({
	match = { class = "ghostty" },
	opacity = "0.8 override 0.8 override 1.0 override",
})
hl.window_rule({
	-- The syland-context dev terminal (see home/syland-context.nix's
	-- ensure_devterm) launches ghostty with this dedicated class
	-- specifically so it lands on its own hidden special workspace
	-- instead of the normal workspace flow, confirmed live via
	-- `hyprctl dispatch 'hl.dsp.workspace.toggle_special("dev")'`.
	match = { class = "com.syland.devterm" },
	workspace = "special:dev",
})
hl.window_rule({
	-- Same hidden-special-workspace pattern as com.syland.devterm above
	-- -- started at Hyprland startup (home/hypr/base.lua's own
	-- hl.on("hyprland.start", ...) hook) so it's already running in the
	-- background for new-mail notifications (Thunderbird's own "show an
	-- alert" preference, routed through this shell's normal
	-- NotificationService like any other app's desktop notification --
	-- nothing extra to wire up on the quickshell side), and only shown
	-- on demand via SUPER+E (home/hypr/keybinds.lua). "thunderbird" is
	-- the upstream WM_CLASS -- VERIFY live if this rule doesn't seem to
	-- take (`hyprctl clients -j` while it's running will show the real
	-- class if it's ever renamed upstream).
	--
	-- "silent" -- without it, assigning a window to a workspace via
	-- rule also switches focus to that workspace the instant the
	-- window is created (confirmed live: Thunderbird was the first
	-- thing visible on boot, special:mail having auto-focused). silent
	-- keeps window creation itself from stealing focus, so it actually
	-- stays hidden until SUPER+E.
	match = { class = "thunderbird" },
	workspace = "special:mail silent",
})

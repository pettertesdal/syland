hl.layer_rule({
	match = {namespace = "quickshell"},
	blur = true,
	no_anim = true,
}),
hl.window_rule({
	match = { class = "ghostty" },
	opacity = "0.8 override 0.8 override 1.0 override",
	blue.enable = true,
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

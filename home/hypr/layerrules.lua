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

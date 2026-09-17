{ ... }:

{
	home.file.".config/hypr".source = ./hypr;
	home.file.".config/quickshell".source = ./quickshell;
	home.file.".config/ghostty".source = ./ghostty;
	home.file.".config/syland/themes-src".source = ./themes;
	home.file.".config/cava".source = ./cava;

	# Standalone lock config (home/syland-lock.nix) — a separate deploy
	# from .config/quickshell above, not a subdirectory of it, since it's
	# a genuinely separate quickshell process/config tree. The theme/
	# copy is an explicit second entry rather than relying on a relative
	# QML import reaching into .config/quickshell/src/theme instead — so
	# this dependency shows up here, where the rest of the deployment
	# wiring already lives, instead of failing silently at lock-time if
	# home/quickshell/src/theme/ ever moves.
	home.file.".config/quickshell-lock".source = ./quickshell-lock;
	home.file.".config/quickshell-lock/theme".source = ./quickshell/src/theme;
}

{ ... }:

{
	home.file.".config/hypr".source = ./hypr;
	home.file.".config/quickshell".source = ./quickshell;
	home.file.".config/ghostty".source = ./ghostty;
	home.file.".config/syland/themes-src".source = ./themes;
	home.file.".config/cava".source = ./cava;

	# Standalone lock config (home/syland-lock.nix) — a separate deploy
	# from .config/quickshell above, not a subdirectory of it, since it's
	# a genuinely separate quickshell process/config tree. Individual
	# per-file entries, not one directory-level `.source = ./quickshell-lock`
	# entry — a directory-level home.file entry claims that whole
	# directory as a single symlink, which then collides with any other
	# entry trying to place something *inside* it (confirmed live:
	# "Error installing file '.config/quickshell-lock/theme' outside
	# $HOME" the first time this was one entry + a nested theme entry).
	# The theme/ line is an explicit dependency here — visible in the Nix
	# module graph, not an implicit relative QML import reaching into
	# .config/quickshell/src/theme that would fail silently at lock-time
	# if home/quickshell/src/theme/ ever moves.
	home.file.".config/quickshell-lock/shell.qml".source = ./quickshell-lock/shell.qml;
	home.file.".config/quickshell-lock/LockContext.qml".source = ./quickshell-lock/LockContext.qml;
	home.file.".config/quickshell-lock/LockSurface.qml".source = ./quickshell-lock/LockSurface.qml;
	home.file.".config/quickshell-lock/theme".source = ./quickshell/src/theme;
}

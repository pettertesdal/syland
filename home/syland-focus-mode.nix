# syland-focus-mode: backend for the Hyprland SUPER+F1 toggle (see
# home/hypr/keybinds.lua) and src/state/IpcManager.qml's "focus-mode" IPC
# target. ShellState.focusMode in QML is the sole source of truth for
# on/off state -- this script is never asked to "toggle", only ever told
# which state to enter.
{ pkgs, ... }:
let
	sylandFocusMode = pkgs.writeShellApplication {
		name = "syland-focus-mode";
		runtimeInputs = [ pkgs.systemd ];
		text = ''
			mode="''${1:-}"
			case "$mode" in
				on)
					systemctl --user stop hypridle.service
					;;
				off)
					systemctl --user start hypridle.service
					;;
				*)
					echo "usage: syland-focus-mode {on|off}" >&2
					exit 1
					;;
			esac
		'';
	};
in {
	home.packages = [ sylandFocusMode ];
}

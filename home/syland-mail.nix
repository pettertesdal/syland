# syland-mail-toggle: backend for the Hyprland SUPER+E keybind
# (home/hypr/keybinds.lua). Thunderbird is started once at Hyprland
# startup (home/hypr/base.lua's own hyprland.start hook) hidden on its
# own special workspace (home/hypr/layerrules.lua's window rule) --
# this ensures it's actually still running (relaunching if the window
# was closed since startup) before toggling that workspace's
# visibility, since a plain toggle_special() call alone would otherwise
# just show/hide an empty special workspace forever once the window's
# ever closed.
{ pkgs, ... }:
let
	sylandMailToggle = pkgs.writeShellApplication {
		name = "syland-mail-toggle";
		runtimeInputs = [ pkgs.hyprland pkgs.jq pkgs.thunderbird ];
		text = ''
			MAIL_CLASS="thunderbird"
			existing=$(hyprctl clients -j | jq -r --arg class "$MAIL_CLASS" '.[] | select(.class == $class) | .pid' | head -n1)
			if [ -z "$existing" ]; then
				thunderbird >/dev/null 2>&1 &
				disown
			fi
			hyprctl dispatch 'hl.dsp.workspace.toggle_special("mail")'
		'';
	};
in {
	home.packages = [ sylandMailToggle ];
}

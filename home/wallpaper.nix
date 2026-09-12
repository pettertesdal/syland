# Wallpaper daemon; images it uses live in home/themes/.
#
# NOT using home-manager's services.awww module: it wires a systemd user
# service gated on graphical-session.target (WantedBy/After/PartOf), but
# that target never activates on this system -- confirmed live
# (`systemctl --user status graphical-session.target` shows inactive) --
# since Hyprland is launched raw here, not through uwsm (see base.lua's
# own hl.env comment for the same class of issue with PATH). Instead
# awww-daemon is started directly from Hyprland's own startup hook in
# home/hypr/base.lua, the same way qs/mako already are.
{ pkgs, ... }:

{
	home.packages = [ pkgs.awww ];
}

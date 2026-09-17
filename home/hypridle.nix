# hypridle: idle-triggered and pre-sleep session lock. Not using
# home-manager's services.hypridle module -- it writes its generated
# config to ~/.config/hypr/hypridle.conf, but home/dotfiles.nix already
# claims the *entire* .config/hypr directory as one home.file entry (a
# symlink to the git-tracked home/hypr/ tree) -- a home-manager
# generated file can't be placed inside a directory another home.file
# entry has already wholesale-claimed. Confirmed live: "Error installing
# file '.config/hypr/hypridle.conf' outside $HOME".
#
# Fixed the same class of way home/wallpaper.nix already works around a
# home-manager module fighting this system's own conventions: hand-write
# the real hyprlang config as home/hypr/hypridle.conf (a plain
# git-tracked file, deployed for free through dotfiles.nix's existing
# .config/hypr entry, no new home.file needed) and hand-roll the systemd
# unit here instead of letting the module generate one.
#
# Not auto-started via WantedBy either, for the same reason
# home/wallpaper.nix's own services.awww avoidance exists:
# graphical-session.target never activates on this system (Hyprland is
# launched raw, not via uwsm). Started explicitly instead, from
# home/hypr/base.lua's own hl.on("hyprland.start", ...) hook.
{ pkgs, ... }:

{
  home.packages = [ pkgs.hypridle ];

  systemd.user.services.hypridle = {
    Unit.Description = "Hyprland idle daemon";
    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
  };
}

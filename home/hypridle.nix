# hypridle: idle-triggered and pre-sleep session lock, both calling
# `systemctl --user start syland-lock.service` (home/syland-lock.nix) —
# a safe no-op if already locked, so no separate dedup logic needed here.
#
# services.hypridle.enable used for config generation only (produces a
# real ~/.config/hypr/hypridle.conf via home-manager's own templating,
# nicer than hand-writing hyprlang), but NOT relied on for auto-start:
# its systemd unit is WantedBy/PartOf graphical-session.target, which
# home/wallpaper.nix already diagnosed as never activating on this
# system (Hyprland is launched raw, not via uwsm) — the exact same
# reason services.awww was abandoned there in favor of starting
# awww-daemon directly from home/hypr/base.lua's own hl.on("hyprland.start", ...)
# hook. hypridle.service gets started from that same hook instead.
{ ... }:

{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "systemctl --user start syland-lock.service";
        before_sleep_cmd = "systemctl --user start syland-lock.service";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "systemctl --user start syland-lock.service";
        }
      ];
    };
  };
}

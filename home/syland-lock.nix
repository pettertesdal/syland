# Session lock — home/quickshell-lock/ is the actual QML (see its own
# shell.qml comment), this just supervises the process. A systemd user
# service rather than a bare backgrounded command, for two reasons at
# once: `systemctl --user start syland-lock.service` on an already-active
# unit is a safe no-op, so the idle timeout firing repeatedly or the
# manual keybind firing while already locked can't spawn a second lock
# process (no separate pgrep/dedup script needed); and Restart=on-failure
# means if the quickshell-lock process itself crashes, it comes back up
# automatically — WlSessionLock's own documented behavior is that a
# conformant compositor leaves the screen locked and blanked if the
# locking client dies, which without a supervisor would mean a genuinely
# un-interactable dead lock screen, not just "still locked". Same
# systemd.user.services pattern home/mpd.nix already uses.
{ pkgs, ... }:

{
  systemd.user.services.syland-lock = {
    Unit.Description = "Quickshell session lock";
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell -c %h/.config/quickshell-lock";
      Restart = "on-failure";
    };
  };
}

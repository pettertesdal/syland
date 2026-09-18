# Replaces plain getty autologin (see git history) -- that approach left
# tty1's own getty racing Hyprland for the VT/DRM device on every boot,
# via systemd's own getty@.service unit shipping a hard-coded
# `Conflicts=`/`After=plymouth-quit.service` (not something Plymouth's own
# package advertises -- confirmed live, twice, via journalctl +
# systemd-coredump: disabling plymouth-quit(-wait).service to fix the
# cosmetic "flash of tty1's login prompt" broke that serialization and
# crashed Hyprland's own initServer() with SIGABRT instead).
#
# This is the same pattern real display managers and Arch's own
# autologin-to-X wiki recipe use: a dedicated systemd service that
# Conflicts= getty@tty1.service directly (so the VT handoff is ours to
# control, not getty's), and is `Before=` plymouth-quit(-wait).service
# (native systemd ordering -- those units still exist and still run, they
# just wait for us, instead of being disabled and breaking getty's own
# ordering).
{ pkgs, ... }:

{
	systemd.services.hyprland-session = {
		description = "Hyprland session on tty1";
		conflicts = [ "getty@tty1.service" ];
		after = [ "systemd-user-sessions.service" "getty@tty1.service" ];
		before = [ "plymouth-quit.service" "plymouth-quit-wait.service" ];
		wantedBy = [ "graphical.target" ];
		# This unit IS the live, running desktop session, not a display
		# manager sitting outside it -- unlike a normal system service,
		# restarting it kills the actual compositor mid-session.
		# ExecStart/ExecStartPre both bake in absolute nix store paths
		# (${pkgs.hyprland}, ${pkgs.plymouth}), which change on nearly
		# every `nixos-rebuild switch` even from unrelated package bumps,
		# so NixOS's default restartIfChanged=true was force-restarting
		# this (confirmed live: `nixos-rebuild switch` reliably dropped
		# the session straight to tty1's own getty, since this service
		# Conflicts= it) on almost every switch. false here means a
		# `switch` still updates everything else live as normal, this one
		# service just waits for the next actual reboot (or a manual
		# `systemctl restart hyprland-session.service`, if ever wanted)
		# to pick up its own changes instead of being bounced out from
		# under the user mid-session.
		restartIfChanged = false;

		serviceConfig = {
			User = "tesdap";
			PAMName = "login";
			TTYPath = "/dev/tty1";
			Type = "simple";
			# "-" prefix: best-effort, non-fatal if plymouth isn't running
			# (e.g. boot.plymouth.enable ever gets turned off) -- stops
			# Plymouth actively repainting right as Hyprland is about to
			# grab the display, without fully tearing it down yet (that's
			# still Plymouth's fallback state if Hyprland itself fails to
			# start). home/hypr/base.lua's own hl.on("hyprland.start", ...)
			# hook issues the actual `plymouth quit --wait` once
			# syland-lock.service is confirmed up, not here -- this
			# service is "started" the instant start-hyprland is forked
			# (Type=simple), well before anything's actually painted.
			ExecStartPre = "-${pkgs.plymouth}/bin/plymouth deactivate";
			ExecStart = "${pkgs.hyprland}/bin/start-hyprland";
			StandardOutput = "journal";
			StandardError = "journal";
		};
	};
}

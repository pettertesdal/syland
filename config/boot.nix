{ ... }:

{
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	# Works around flickering on the two external monitors connected
	# through the HP Elite USB-C Dock G4's DP MST hub (kernel logs
	# "i915 ... Failed to get ACT after 3000 ms" during the flicker).
	boot.kernelParams = [
		"i915.enable_psr=0"
		# Plymouth boot splash -- hides kernel/systemd boot text between
		# the bootloader and config/autologin.nix's own tty1 autologin,
		# through to Hyprland's own handoff -- see home/hypr/base.lua's
		# own plymouth-quit call for where that splash actually ends.
		"quiet"
		"rd.systemd.show_status=auto"
		"rd.udev.log_level=3"
		"udev.log_priority=3"
	];
	boot.consoleLogLevel = 3;
	boot.initrd.verbose = false;

	boot.plymouth = {
		enable = true;
		# Default theme (bgrt) just shows the firmware/vendor logo,
		# static -- confirmed live that read as "screen goes black" with
		# nothing to actually see. spinner is a real built-in animated
		# theme (no extra theme package to fetch).
		theme = "spinner";
	};
}

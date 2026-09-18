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
		# the bootloader and config/hyprland-session.nix's own tty1
		# session start, through to Hyprland's own handoff -- see that
		# file's own ExecStartPre plus home/hypr/base.lua's own
		# `plymouth quit --wait` call for where that splash actually ends.
		"quiet"
		"rd.systemd.show_status=auto"
		"rd.udev.log_level=3"
		"udev.log_priority=3"
	];
	boot.consoleLogLevel = 3;
	boot.initrd.verbose = false;

	# Plymouth needs KMS to render anything graphical -- without the GPU
	# driver loaded this early, it silently falls back to text mode
	# during boot (invisible under "quiet" above), which is why the
	# spinner theme didn't show at all despite plymouth-poweroff working
	# fine at shutdown (by then i915 is already loaded via the normal,
	# late boot path -- hardware-configuration.nix's own
	# boot.initrd.kernelModules is empty, i915 was never in the initrd).
	# NixOS list options merge across files, so this adds to that list
	# rather than needing to hand-edit the auto-generated file.
	boot.initrd.kernelModules = [ "i915" ];

	boot.plymouth = {
		enable = true;
		# Default theme (bgrt) just shows the firmware/vendor logo,
		# static -- confirmed live that read as "screen goes black" with
		# nothing to actually see. spinner is a real built-in animated
		# theme (no extra theme package to fetch).
		theme = "spinner";
	};
}

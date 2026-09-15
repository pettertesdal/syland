{ ... }:

{
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	# Works around flickering on the two external monitors connected
	# through the HP Elite USB-C Dock G4's DP MST hub (kernel logs
	# "i915 ... Failed to get ACT after 3000 ms" during the flicker).
	boot.kernelParams = [ "i915.enable_psr=0" ];
}

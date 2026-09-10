# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
	imports =
		[ # Include the results of the hardware scan.
		./hardware-configuration.nix
		];

# Use the systemd-boot EFI boot loader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "penguin-b"; # Define your hostname.
# networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

# Configure network proxy if necessary
# networking.proxy.default = "http://user:password@proxy:port/";
# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

# Enable networking
		networking.networkmanager.enable = true;

# Set your time zone.
	time.timeZone = "Europe/Oslo";

# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	i18n.extraLocaleSettings = {
		LC_ADDRESS = "nb_NO.UTF-8";
		LC_IDENTIFICATION = "nb_NO.UTF-8";
		LC_MEASUREMENT = "nb_NO.UTF-8";
		LC_MONETARY = "nb_NO.UTF-8";
		LC_NAME = "nb_NO.UTF-8";
		LC_NUMERIC = "nb_NO.UTF-8";
		LC_PAPER = "nb_NO.UTF-8";
		LC_TELEPHONE = "nb_NO.UTF-8";
		LC_TIME = "nb_NO.UTF-8";
	};

# Configure keymap in X11
	services.xserver.xkb = {
		layout = "no";
		variant = "";
	};

# Configure console keymap
	console.keyMap = "no";

# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users."tesdap" = {
		isNormalUser = true;
		description = "Petter Tesdal";
		extraGroups = [ "networkmanager" "wheel" ];
		packages = with pkgs; [];
	};

# Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	programs.firefox.enable = true;

	programs.hyprland = {
		enable = true;
		xwayland.enable = true;
	};

	# Required for Quickshell.Bluetooth/UPower (src/services/BluetoothStatusService.qml,
	# modules/BatteryIndicator.qml) to have an adapter/battery to report on.
	hardware.bluetooth.enable = true;
	services.blueman.enable = true;
	services.upower.enable = true;

# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
	environment.systemPackages = with pkgs; [
		vim
			git
			kitty
			firefox
			ghostty
			quickshell
			jq
			yq
			fzf
			libnotify
	];

	fonts.packages = with pkgs; [
			nerd-fonts.proggy-clean-tt
	];



# Open ports in the firewall.
# networking.firewall.allowedTCPPorts = [ ... ];
# networking.firewall.allowedUDPPorts = [ ... ];
# Or disable the firewall altogether.
# networking.firewall.enable = false;

# Copy the NixOS configuration file and link it from the resulting system
# (/run/current-system/configuration.nix). This is useful in case you
# accidentally delete configuration.nix.
# system.copySystemConfiguration = true;

# This option defines the first version of NixOS you have installed on this particular machine,
# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
#
# Most users should NEVER change this value after the initial install, for any reason,
# even if you've upgraded your system to a new NixOS release.
#
# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
# to actually do that.
#
# This value being lower than the current NixOS release does NOT mean your system is
# out of date, out of support, or vulnerable.
#
# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
# and migrated your data accordingly.
#
# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	system.stateVersion = "26.05"; # Did you read the comment?

}

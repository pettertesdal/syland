{ pkgs, ... }:

{
	# Deliberately minimal: a basic editor and git available system-wide even
	# if the home-manager profile fails to activate. Everything else the user
	# actually runs (terminals, CLI tools, music players, ...) lives in
	# home/packages.nix instead — see https://search.nixos.org/ to find more.
	environment.systemPackages = with pkgs; [
		vim
		git
	];
}

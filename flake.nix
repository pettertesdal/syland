{
	description = "NixOS flake for the Syland system";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-26.05";
		home-manager = {
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		pins.url = "path:./pins";
	};

	outputs = { self, nixpkgs, home-manager, pins, ...}:
	let
		system = "x86_64-linux";
		stableChannel = "26.05"; # keep in sync with the nixpkgs input's release above
	in {
		nixosConfigurations.penguin-b= nixpkgs.lib.nixosSystem {
			inherit system;
			modules = [
				{ nixpkgs.overlays = [ pins.overlays.default ]; }
				./configuration.nix
					home-manager.nixosModules.home-manager
					{
						home-manager = {
							useGlobalPkgs = true;
							useUserPackages = true;
							users.tesdap = import ./home.nix;
							backupFileExtension = "backup";
							extraSpecialArgs = { inherit stableChannel; pinsData = pins.pinsData; };
						};
					}
			];
		};
	};
}

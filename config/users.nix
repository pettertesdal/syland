{ ... }:

{
	users.users."tesdap" = {
		isNormalUser = true;
		description = "Petter Tesdal";
		extraGroups = [ "networkmanager" "wheel" ];
		packages = [ ];
	};
}

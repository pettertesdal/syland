{
  description = "Independent, per-package pins ahead of the main nixpkgs channel";

  inputs = {
    nixpkgs-nix-search-tv.url = "github:NixOS/nixpkgs?rev=5036dc112738f8b5af518c5a7af4098a2ec81417";
    # Add one dedicated input per future pin here.
  };

  outputs = { self, ... }@inputs:
  let
    system = "x86_64-linux";
    pins = import ./pins.nix;
    pkgsFor = pin: import inputs.${pin.inputName} { inherit system; };
  in {
    overlays.default = final: prev:
      builtins.listToAttrs (map (pin: {
        name = pin.name;
        value = (pkgsFor pin).${pin.name};
      }) pins);

    # Pure data: each pin plus its resolved version string, for the checker script.
    pinsData = map (pin: pin // { pinnedVersion = (pkgsFor pin).${pin.name}.version; }) pins;
  };
}

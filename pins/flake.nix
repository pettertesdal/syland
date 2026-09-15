{
  description = "Independent, per-package pins ahead of the main nixpkgs channel";

  inputs = {
    nixpkgs-nix-search-tv.url = "github:NixOS/nixpkgs?rev=5036dc112738f8b5af518c5a7af4098a2ec81417";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    # Add one dedicated input per future pin here.
  };

  outputs =
    { self, ... }@inputs:
    let
      system = "x86_64-linux";
      pins = import ./pins.nix;
      # Two pin shapes: most pins are a nixpkgs revision, pinned to grab one
      # package ahead of the main channel -- `import <nixpkgs> { system }`
      # then pick the attr by name. Pins marked `flakePackage` are instead
      # standalone flakes (not nixpkgs checkouts) pinned for their own
      # `packages.<system>.default` output directly -- e.g. zen-browser-flake,
      # whose legacy default.nix needs a `pkgs` arg this flake has no way to
      # supply, so the nixpkgs-shaped import doesn't apply to it.
      pkgFor =
        pin:
        if pin.flakePackage or false then
          inputs.${pin.inputName}.packages.${system}.${pin.attr or "default"}
        else
          (import inputs.${pin.inputName} { inherit system; }).${pin.name};
    in
    {
      overlays.default =
        final: prev:
        builtins.listToAttrs (
          map (pin: {
            name = pin.name;
            value = pkgFor pin;
          }) pins
        );

      # Pure data: each pin plus its resolved version string, for the checker script.
      pinsData = map (pin: pin // { pinnedVersion = (pkgFor pin).version; }) pins;
    };
}

[
  {
    name = "nix-search-tv";
    inputName = "nixpkgs-nix-search-tv";
    reason = "26.05 nixpkgs ships 2.2.7 with a known bug; fixed in nixpkgs by 2.2.9 (commit 5036dc1)";
    dateAdded = "2026-09-10";
  }
  {
    name = "zen-browser";
    inputName = "zen-browser";
    flakePackage = true;
    reason = "fast-moving upstream; want current releases rather than whatever's packaged in nixpkgs";
    dateAdded = "2026-09-15";
  }
]

# User-level (home-manager) configuration for tesdap, split by concern into
# home/. configuration.nix + config/ own everything system-level instead —
# see README.txt.
{
  config,
  pkgs,
  lib,
  pinsData,
  stableChannel,
  nvf,
  ...
}:

{
  imports = [
    ./home/packages.nix
    ./home/pins-check.nix
    ./home/shell.nix
    ./home/mpd.nix
    ./home/rmpc.nix
    ./home/dotfiles.nix
    ./home/wallpaper.nix
    ./home/theme-apply.nix
    ./home/nvf.nix
    ./home/yazi.nix
    ./home/zellij.nix
    ./home/syland-context.nix
    ./home/syland-todo.nix
    ./home/obsidian.nix
  ];

  home.username = "tesdap";
  home.homeDirectory = "/home/tesdap";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}

{ pkgs, ... }:

{
  # Interactive/GUI tools for this user. System-wide package installs
  # (vim, git only) live in config/packages.nix instead — see README.txt.
  home.packages = with pkgs; [
    kitty
    ghostty
    quickshell
    jq
    yq
    libnotify
    kew
    cliamp
    devenv
    zathura
  ];
}

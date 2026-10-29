{ pkgs, ... }:

{
  # Interactive/GUI tools for this user. System-wide package installs
  # (vim, git only) live in config/packages.nix instead — see README.txt.
  home.packages = with pkgs; [
    kitty
    gh
    mdcat
    ghostty
    quickshell
    jq
    yq
    libnotify
    kew
    cliamp
    cava
    devenv
    # IntelliJ -- jetbrains.idea-community was discontinued by JetBrains
    # in 2025 (Community/Ultimate unified into one distribution); this is
    # the official unified binary (free at the Community feature tier,
    # Ultimate features need a license), not jetbrains.idea-oss (nixpkgs'
    # own from-source rebuild, noticeably behind on releases).
    jetbrains.idea
    zathura
    zen-browser
    thunderbird
    taskwarrior3
    wireshark-cli
  ];
}

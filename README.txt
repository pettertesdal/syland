# Layout
home.nix and configuration.nix are just thin indexes: each `imports` a list of
small, single-concern modules instead of holding everything inline.

- home/   user-level home-manager modules (packages.nix, shell.nix, mpd.nix,
          rmpc.nix, pins-check.nix, dotfiles.nix, wallpaper.nix), plus the
          actual dotfile trees those modules point at (ghostty/, hypr/,
          nvim/, quickshell/, themes/)
- config/ system-level NixOS modules (boot.nix, networking.nix, locale.nix,
          users.nix, graphical.nix, bluetooth.nix, fonts.nix, packages.nix,
          nix.nix)

Rule of thumb for where something goes: if it's a package/service/dotfile
only this user needs (a CLI tool, a program's config file), it's home/. If
it's needed regardless of who's logged in (boot, networking, hardware
enablement, fonts, the recovery-toolkit vim+git in config/packages.nix), it's
config/.

# TODO
- Add nvf to configure nvim as a standalone installation
- JellyfinTUI ?

Project management (syland-context, syland-todo) is done — see CLAUDE.md.

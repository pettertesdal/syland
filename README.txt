# Layout
- home/   user-level dotfiles referenced from home.nix (home.file.".config/X".source = ./home/X)
- config/ system-level file fragments referenced from configuration.nix, once any exist
          (configuration.nix is currently self-contained, so this stays empty for now)

# TODO
- Add nvf to configure nvim as a standalone installation
- Add project management, making projects quickly viewable, along with their documentation.
- JellyfinTUI ?

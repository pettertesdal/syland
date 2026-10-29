{ pkgs, ... }:

{
	programs = {
		zsh = {
			enable = true;
			enableCompletion = true;
			autosuggestion.enable = true;
			syntaxHighlighting.enable = true;
			shellAliases = {
				update = "sudo nixos-rebuild switch --flake $HOME/.syland#penguin-b";
			};
			history.size = 10000;
			history.ignoreAllDups = true;
			history.path = "$HOME/.zsh_history";
		};

		starship = {
			enable = true;

			settings = {
				add_newline = true;

				format = "$directory$git_branch$git_status$character";

				directory = {
					truncation_length = 3;
				};

				git_branch = {
					format = " [$branch]($style)";
				};

				character = {
					success_symbol = "[❯](bold green)";
					error_symbol = "[❯](bold red)";
				};
			};
		};

		direnv = {
			enable = true;
			nix-direnv.enable = true;
			enableZshIntegration = true;
		};

		fzf = {
			enable = true;
			enableZshIntegration = true;
		};

		zoxide = {
			enable = true;
			enableZshIntegration = true;
		};

		claude-code.enable = true;

		nix-search-tv.enable = true;
	};
# Companion helper for nix-search-tv: wraps its own nixpkgs.sh script
# under a short "ns" command.
	home.packages = [
		(pkgs.writeShellApplication {
		 name = "ns";
		 text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
		 })
	];

	# direnv's own "lib" dir (direnv.lib above already deploys
	# nix-direnv's own snippet the same way, as direnv/lib/hm-nix-direnv.sh)
	# auto-sources every .sh file dropped in it for every .envrc, which is
	# how the `use_devenv` shell function a plain `use devenv` line needs
	# gets defined -- confirmed live this didn't exist before: a project
	# scaffolded by syland-context's `create` (home/syland-context.nix,
	# writes ".envrc" containing just "use devenv") failed with
	# "use_devenv: command not found" on `direnv allow`. devenv doesn't
	# ship this as a static file the way nix-direnv does (only a man
	# page) -- `devenv direnvrc` prints it dynamically, so this captures
	# that output at build time from the actual pinned devenv package,
	# rather than hand-copying a snippet that could drift from whatever
	# version is really installed.
	#
	# devenv's own snippet is itself "adapted from nix-direnv's own
	# direnvrc" (its own header comment says so) and keeps the exact same
	# internal helper name, _nix_direnv_preflight, as nix-direnv's real
	# direnvrc (direnv/lib/hm-nix-direnv.sh, deployed separately above via
	# nix-direnv.enable) -- a real, confirmed-live collision: direnv loads
	# every direnv/lib/*.sh file for every .envrc regardless of which one
	# a given project's .envrc actually calls, and alphabetically
	# hm-nix-direnv.sh loads *after* hm-devenv.sh, so its own
	# _nix_direnv_preflight (which never sets DEVENV_BIN) silently
	# overwrites devenv's own version of that same-named function. The
	# result: `use devenv` ends up calling nix-direnv's preflight instead
	# of its own, DEVENV_BIN stays empty, and direnv aborts with a
	# cryptic "`: command not found`". Renaming just this file's own copy
	# of the function (definition and its one call site) to something
	# that can't collide fixes this without touching the
	# separately-owned nix-direnv file or depending on load order at all.
	xdg.configFile."direnv/lib/hm-devenv.sh".source = pkgs.runCommand "hm-devenv-direnvrc" { } ''
		${pkgs.devenv}/bin/devenv direnvrc \
			| sed 's/_nix_direnv_preflight/_devenv_nix_direnv_preflight/g' \
			> $out
	'';
}

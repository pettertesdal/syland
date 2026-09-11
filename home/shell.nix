{ pkgs, ... }:

{
	programs.zsh = {
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

	programs.starship = {
		enable = true;

		settings = {
			add_newline = false;

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

	programs.direnv = {
		enable = true;
		enableZshIntegration = true;
	};

	programs.claude-code.enable = true;

	programs.nix-search-tv.enable = true;
	# Companion helper for nix-search-tv: wraps its own nixpkgs.sh script
	# under a short "ns" command.
	home.packages = [
		(pkgs.writeShellApplication {
			name = "ns";
			text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
		})
	];
}

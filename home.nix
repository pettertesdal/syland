{ config, pkgs, lib, pinsData, stableChannel, ... }:

let
pinsCheck = pkgs.writeShellApplication {
	name = "pins-check";
	runtimeInputs = [ pkgs.curl pkgs.jq pkgs.libnotify ];
	text = lib.concatMapStringsSep "\n" (pin: ''
			live_version=$(curl -su 'aWVSALXpZv:X8gPHnzL52wFEekuxsfQ9cSh' \
				-X POST 'https://nixos-search-7-1733963800.us-east-1.bonsaisearch.net:443/latest-*-nixos-${stableChannel}/_search' \
				-H 'Content-Type: application/json' \
				-d '{"query":{"bool":{"must":[{"match":{"type":"package"}},{"dis_max":{"queries":[{"wildcard":{"package_attr_name":{"value":"${pin.name}*"}}}]}}]}}}' \
				| jq -r --arg n "${pin.name}" '.hits.hits[] | select(._source.package_attr_name == $n) | ._source.package_pversion' | head -n1)
			pinned_version="${pin.pinnedVersion}"
			if [ "$(printf '%s\n%s' "$pinned_version" "$live_version" | sort -V | tail -n1)" = "$live_version" ]; then
			notify-send "Nix pin stale: ${pin.name}" "stable nixpkgs ($live_version) has caught up (${pin.reason}, pinned ${pin.dateAdded}). Remove it from pins/pins.nix and pins/flake.nix."
			fi
			'') pinsData;
};
in {
	home.username = "tesdap";
	home.homeDirectory = "/home/tesdap";
	home.stateVersion = "26.05";

	home.packages = with pkgs; [
		cliamp
		pinsCheck
			(pkgs.writeShellApplication {
			 name = "ns";
			 text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
			 })
	devenv
	];

	systemd.user.services.pins-check = {
		Unit.Description = "Check whether pinned Nix packages are still needed";
		Service = { Type = "oneshot"; ExecStart = "${pinsCheck}/bin/pins-check"; };
	};

	systemd.user.timers.pins-check = {
		Unit.Description = "Daily check for stale Nix pins";
		Timer = { OnCalendar = "daily"; Persistent = true; };
		Install.WantedBy = [ "timers.target" ];
	};

	services.awww.enable = true;

	services.mpd = {
		enable = true;
		musicDirectory = "${config.home.homeDirectory}/media/music";
	};

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
		claude-code = {
			enable = true;
		};
		nix-search-tv.enable = true;
		rmpc.enable = true;
		direnv = {
			enable = true;
			enableZshIntegration = true;
		};
		starship = {
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
	};


	home.file.".config/hypr".source = ./home/hypr;
	home.file.".config/quickshell".source = ./home/quickshell;
	home.file.".config/ghostty".source = ./home/ghostty;

	programs.home-manager.enable = true;
}

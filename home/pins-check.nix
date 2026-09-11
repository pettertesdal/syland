# Daily staleness check for the per-package nixpkgs pins in pins/ (see
# pins/pins.nix) — notifies when the pinned stable channel has caught up to
# the fix a pin exists for, so it's safe to remove.
{ pkgs, lib, pinsData, stableChannel, ... }:

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
	home.packages = [ pinsCheck ];

	systemd.user.services.pins-check = {
		Unit.Description = "Check whether pinned Nix packages are still needed";
		Service = { Type = "oneshot"; ExecStart = "${pinsCheck}/bin/pins-check"; };
	};

	systemd.user.timers.pins-check = {
		Unit.Description = "Daily check for stale Nix pins";
		Timer = { OnCalendar = "daily"; Persistent = true; };
		Install.WantedBy = [ "timers.target" ];
	};
}

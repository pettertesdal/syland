# syland-context: finishes the project-switching/docs-reading scaffolding
# that's already sitting in home/hypr/keybinds.lua and in
# src/popups/Picker.qml's "Context" category (which already calls `list`
# and `set <path>` -- nothing implementing either existed until now, same
# situation syland-theme-apply was in before it got built).
#
# Reads the real ~/projects/<category>/<name>/{documents/,repos/<repo>/}
# convention already in use (e.g. ~/projects/work/SeaR). "documents/" holds
# PDFs/docs, "repos/" holds one or more actual git checkouts.
{ pkgs, ... }:
let
	sylandContext = pkgs.writeShellApplication {
		name = "syland-context";
		# Deliberately no neovim/nvf package here: writeShellApplication
		# prepends runtimeInputs onto PATH rather than replacing it, so
		# plain `nvim` still resolves to the nvf-configured binary already
		# on the normal home-manager profile PATH.
		runtimeInputs = [ pkgs.fzf pkgs.jq pkgs.findutils pkgs.coreutils pkgs.zellij pkgs.zathura pkgs.ghostty pkgs.hyprland ];
		text = ''
			PROJECTS_DIR="$HOME/projects"
			STATE_DIR="$HOME/.config/syland/context"
			STATE_FILE="$STATE_DIR/state.json"
			DEV_CLASS="com.syland.devterm"
			mkdir -p "$STATE_DIR"

			require_state() {
				if [ ! -f "$STATE_FILE" ]; then
					echo "syland-context: no active project -- pick one from the menu (Context), or run 'syland-context set <repo_path>'" >&2
					exit 1
				fi
			}

			# ensure_devterm <repo_path> -- makes the dev terminal show
			# this project, reusing the existing window/session if one is
			# already open instead of spawning a second one.
			#
			# Both branches below were verified live, not assumed:
			# - Closing a session's last tab kills the whole session, so
			#   new tabs are always created *before* the old ones are
			#   closed (confirmed live: doing it the other way around
			#   destroyed the session).
			# - `new-tab --layout <name>` does NOT replicate a multi-tab
			#   layout file (confirmed live: produced exactly one tab and
			#   even ignored --name) -- hence two explicit new-tab calls.
			# - `action switch-session`/`detach`, and session
			#   resurrection, were both tried live as simpler
			#   alternatives and rejected: switch-session sent to an
			#   already-attached session had no visible effect at all
			#   (confirmed via screenshot), and closed sessions didn't
			#   show up as resurrectable even with session_serialization
			#   explicitly enabled.
			ensure_devterm() {
				local repo_path="$1"
				if hyprctl clients -j | jq -e --arg class "$DEV_CLASS" '.[] | select(.class == $class)' >/dev/null 2>&1; then
					local old_tab_ids
					mapfile -t old_tab_ids < <(zellij --session dev action list-tabs -j | jq -r '.[].tab_id')
					zellij --session dev action new-tab --cwd "$repo_path" --name editor -- nvim
					zellij --session dev action new-tab --cwd "$repo_path" --name shell
					local id
					for id in "''${old_tab_ids[@]}"; do
						zellij --session dev action close-tab --tab-id "$id"
					done
				else
					# `zellij attach` has no --layout flag at all -- the
					# "dev" layout can only be requested at creation time
					# via `--new-session-with-layout`, which always
					# starts fresh and errors if a session by that name
					# already exists (both confirmed live). So: if a
					# "dev" session is somehow already running (e.g. its
					# window got closed without the session itself
					# ending), just attach to whatever it already has;
					# otherwise create it fresh with the right layout.
					# Deliberately NOT `--session dev --layout dev` here
					# -- that combination doesn't create anything either
					# (confirmed live: "There is no active session!").
					local zj_cmd
					if zellij list-sessions --short 2>/dev/null | grep -qx dev; then
						zj_cmd="zellij attach dev"
					else
						zj_cmd="zellij --session dev --new-session-with-layout dev"
					fi
					# Ghostty's own `detect` single-instance logic disables
					# single-instance mode whenever CLI args are passed
					# (confirmed in its own docs), so this always spawns a
					# genuinely separate, fresh process -- never proxied
					# to the long-running shared terminal instance the
					# plain "open terminal" keybind uses. The dedicated
					# class also drives the window rule in
					# home/hypr/layerrules.lua that puts this on its own
					# hidden special workspace.
					ghostty --class="$DEV_CLASS" -e sh -c "cd '$repo_path' && exec $zj_cmd" >/dev/null 2>&1 &
					disown
				fi

				# Toggling is a toggle, not a "show" -- only fire it if
				# the special workspace isn't already the visible one, so
				# repeated calls never accidentally hide it. Confirmed
				# live: specialWorkspace.name is "" when hidden,
				# "special:dev" when shown.
				local current_special
				current_special=$(hyprctl monitors -j | jq -r '.[0].specialWorkspace.name')
				if [ "$current_special" != "special:dev" ]; then
					hyprctl dispatch 'hl.dsp.workspace.toggle_special("dev")' >/dev/null 2>&1 || true
				fi
			}

			cmd="''${1:-}"
			case "$cmd" in
				list)
					# One line per actual repo (not per project folder) --
					# matches src/popups/Picker.qml's contextListProc,
					# which expects {label, path} per line.
					find "$PROJECTS_DIR" -mindepth 4 -maxdepth 4 -type d -path '*/repos/*' 2>/dev/null \
						| sort \
						| while read -r repo_path; do
							rel="''${repo_path#"$PROJECTS_DIR"/}"
							label="''${rel//\/repos\//\/}"
							jq -nc --arg label "$label" --arg path "$repo_path" '{label:$label, path:$path}'
						done
					;;
				set)
					repo_path="''${2:?usage: syland-context set <repo_path>}"
					# Walks back up from <PROJECTS_DIR>/<category>/<name>/repos/<repo>.
					project_root=$(dirname "$(dirname "$repo_path")")
					rel="''${project_root#"$PROJECTS_DIR"/}"
					category="''${rel%%/*}"
					name="''${rel#*/}"

					tmp=$(mktemp)
					jq -nc --arg category "$category" --arg name "$name" \
						--arg project_root "$project_root" --arg repo_path "$repo_path" \
						'{category:$category, name:$name, project_root:$project_root, repo_path:$repo_path}' > "$tmp"
					mv "$tmp" "$STATE_FILE"

					ensure_devterm "$repo_path"
					;;
				open)
					require_state
					sub="''${2:-}"
					project_root=$(jq -r .project_root "$STATE_FILE")
					repo_path=$(jq -r .repo_path "$STATE_FILE")
					case "$sub" in
						pdf)
							mapfile -t pdfs < <(find "$project_root/documents" -maxdepth 1 -iname '*.pdf' 2>/dev/null | sort)
							case "''${#pdfs[@]}" in
								0) echo "syland-context: no PDFs under $project_root/documents" >&2; exit 1 ;;
								1) file="''${pdfs[0]}" ;;
								*) file=$(printf '%s\n' "''${pdfs[@]}" | fzf --prompt="pdf> "); [ -n "$file" ] || exit 0 ;;
							esac
							zathura "$file" >/dev/null 2>&1 &
							disown
							;;
						notes)
							todo="$project_root/TODO.md"
							[ -f "$todo" ] || printf '# %s TODO\n\n- [ ] \n' "$(basename "$project_root")" > "$todo"
							ghostty -e nvim "$todo" >/dev/null 2>&1 &
							disown
							;;
						docs)
							mapfile -t docs < <({
								find "$project_root/documents" -maxdepth 1 \( -iname '*.md' -o -iname '*.markdown' -o -iname 'README*' \) 2>/dev/null
								find "$repo_path" -maxdepth 1 \( -iname '*.md' -o -iname '*.markdown' -o -iname 'README*' \) 2>/dev/null
							} | sort)
							case "''${#docs[@]}" in
								0) echo "syland-context: no markdown/README files found" >&2; exit 1 ;;
								1) file="''${docs[0]}" ;;
								*) file=$(printf '%s\n' "''${docs[@]}" | fzf --prompt="doc> "); [ -n "$file" ] || exit 0 ;;
							esac
							ghostty -e nvim "$file" >/dev/null 2>&1 &
							disown
							;;
						project)
							ensure_devterm "$repo_path"
							;;
						*)
							echo "usage: syland-context open {pdf|notes|docs|project}" >&2
							exit 1
							;;
					esac
					;;
				current)
					if [ -f "$STATE_FILE" ]; then
						cat "$STATE_FILE"
					else
						echo '{}'
					fi
					;;
				*)
					echo "usage: syland-context {list|set <repo_path>|open {pdf|notes|docs|project}|current}" >&2
					exit 1
					;;
			esac
		'';
	};
in {
	home.packages = [ sylandContext ];
}

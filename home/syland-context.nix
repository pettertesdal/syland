# syland-context: project-switching/docs-reading, plus per-project dev
# terminals with their own persistent zellij session, plus `create` for
# scaffolding a brand new project (see home/quickshell/src/popups/
# Picker.qml's "+ New Project" flow and home/hypr/keybinds.lua's
# SUPER+ALT+0 for the two new entry points into this).
#
# Reads the real ~/projects/<category>/<name>/{documents/,repo} convention
# already in use (e.g. ~/projects/work/SeaR/repo, one repo per project --
# not repos/<name>/ for multiple). "documents/" holds PDFs/docs. "repo" is
# sometimes itself a symlink (e.g. ~/projects/personal/syland/repo ->
# ~/.syland) rather than a real checkout, which is why `list`/`set` below
# use `find -L` -- without following symlinks, `-type d` would never match
# a symlinked repo since find classifies the link itself (type l) rather
# than what it points at.
{ pkgs, ... }:
let
	sylandContext = pkgs.writeShellApplication {
		name = "syland-context";
		# Deliberately no neovim/nvf package here: writeShellApplication
		# prepends runtimeInputs onto PATH rather than replacing it, so
		# plain `nvim` still resolves to the nvf-configured binary already
		# on the normal home-manager profile PATH.
		runtimeInputs = [
			pkgs.fzf pkgs.jq pkgs.findutils pkgs.coreutils pkgs.zellij
			pkgs.zathura pkgs.ghostty pkgs.hyprland
			pkgs.git # create's git init on freshly scaffolded project repos
		];
		text = ''
			PROJECTS_DIR="$HOME/projects"
			STATE_DIR="$HOME/.config/syland/context"
			STATE_FILE="$STATE_DIR/state.json"
			# Which project's zellij session the currently-open devterm
			# window (if any) was last spawned/attached with -- the one
			# piece of state that makes toggle-devterm (below) able to
			# tell "already open and already showing the right project"
			# apart from "open, but showing someone else's session".
			DEVTERM_SESSION_FILE="$STATE_DIR/devterm-session"
			# One <language>.nix per preset, deployed from
			# home/syland-context-devenvs/ (see this module's own
			# home.file entry below) -- a live symlink to the repo, not
			# copied into the Nix store, so adding/editing a preset here
			# takes effect immediately with no rebuild. `create` below
			# just copies the matching file; there's no "none.nix" since
			# that language means "write nothing".
			DEVENVS_DIR="$HOME/.config/syland/context/devenvs"
			DEV_CLASS="com.syland.devterm"
			mkdir -p "$STATE_DIR"

			require_state() {
				if [ ! -f "$STATE_FILE" ]; then
					echo "syland-context: no active project -- pick one from the menu (Context), or run 'syland-context set <repo_path>'" >&2
					exit 1
				fi
			}

			# sanitize_component <str> -- doubles any literal "-" first so
			# the single "-" joining category and name in session_name_for
			# below can never be mistaken for one that was already part of
			# either string. Two *different* (category, name) pairs must
			# never produce the *same* session name -- plain concatenation
			# could collide (category="work-x" name="y" and category="work"
			# name="x-y" would both naively become "work-x-y"); doubling
			# first means the only unescaped single "-" left anywhere in
			# the output is the real join point, so no two distinct pairs
			# can ever land on the same string. Also collapses anything
			# outside a conservative safe charset down to "_", since
			# category/name come from real directory names that could in
			# principle contain characters that would break the later
			# `zellij --session <name>` invocation's own word-splitting.
			sanitize_component() {
				local s="$1"
				s="''${s//-/--}"
				printf '%s' "$s" | tr -c 'A-Za-z0-9_.-' '_'
			}

			# session_name_for <category> <name> -- deterministic,
			# collision-free zellij session name for a project. One
			# persistent session per project (not one shared "dev"
			# session) -- see open_devterm's own comment for why.
			session_name_for() {
				local category="$1" name="$2"
				printf '%s-%s' "$(sanitize_component "$category")" "$(sanitize_component "$name")"
			}

			# open_devterm <repo_path> <category> <name> -- makes the dev
			# terminal show this specific project's own persistent zellij
			# session, creating it fresh on first use. One-way "show" only
			# -- never hides. See the toggle-devterm subcommand below for
			# the symmetric toggle the dedicated keybind actually uses.
			#
			# Per-project sessions, not tab-juggling inside one shared
			# "dev" session (that's what this function used to do -- the
			# old zellij-tab-dance logic that went with it is gone, it was
			# a workaround specific to the shared-session design).
			# Swapping which project's session an *already open* window
			# shows is NOT possible in-place: zellij action switch-session/
			# detach sent via an external `zellij --session X action ...`
			# invocation are CLIENT-scoped -- they create a disposable
			# client that acts on itself and exits immediately, never
			# touching the real long-lived client already attached inside
			# the open ghostty window (confirmed live: switch-session sent
			# to an already-attached session had no visible effect at
			# all). The only mechanism that actually works is: close the
			# window, then spawn a fresh one attached to the target
			# session -- same idiom as first-ever creation.
			open_devterm() {
				local repo_path="$1" category="$2" name="$3"
				local target_session
				target_session=$(session_name_for "$category" "$name")

				local existing_pid
				existing_pid=$(hyprctl clients -j | jq -r --arg class "$DEV_CLASS" '.[] | select(.class == $class) | .pid' | head -n1)

				local current_session=""
				[ -f "$DEVTERM_SESSION_FILE" ] && current_session=$(cat "$DEVTERM_SESSION_FILE")

				if [ -n "$existing_pid" ] && [ "$current_session" = "$target_session" ]; then
					: # already open and already showing this project -- nothing to touch
				else
					if [ -n "$existing_pid" ]; then
						# A plain kill, not hyprctl dispatch closewindow --
						# confirmed live this system's hyprlua integration
						# intercepts every `hyprctl dispatch <x>` call and
						# re-evaluates <x> as Lua (`hl.dispatch(<x>)`),
						# so stock dispatcher syntax like
						# "closewindow address:..." is a Lua parse error,
						# not a valid dispatch. The Lua-wrapped equivalent,
						# hl.dsp.window.close(), has no targeting
						# parameter at all -- it only ever closes whatever
						# window currently has focus (confirmed live: it
						# closed an unrelated, coincidentally-focused
						# window instead of the one a pid argument asked
						# for). Killing the ghostty process directly by
						# its own pid, already in hand from the same
						# `hyprctl clients -j` query above, sidesteps
						# both problems entirely.
						kill "$existing_pid" >/dev/null 2>&1 || true
					fi

					# Same "attach if a session by this name is already
					# running, otherwise create fresh with the layout"
					# logic as before, just keyed off target_session
					# instead of the one hardcoded "dev" session name.
					# `zellij attach` has no --layout flag -- the "dev"
					# layout (home/zellij.nix) can only be requested at
					# creation time via --new-session-with-layout, which
					# always starts fresh and errors if a session by that
					# name already exists (both confirmed live).
					local zj_cmd
					if zellij list-sessions --short 2>/dev/null | grep -qx "$target_session"; then
						zj_cmd="zellij attach $target_session"
					else
						zj_cmd="zellij --session $target_session --new-session-with-layout dev"
					fi
					# Ghostty's own `detect` single-instance logic disables
					# single-instance mode whenever CLI args are passed
					# (confirmed in its own docs), so this always spawns a
					# genuinely separate, fresh process -- never proxied to
					# the long-running shared terminal instance the plain
					# "open terminal" keybind uses. The dedicated class also
					# drives the window rule in home/hypr/layerrules.lua
					# that puts this on its own hidden special workspace.
					ghostty --class="$DEV_CLASS" -e sh -c "cd '$repo_path' && exec $zj_cmd" >/dev/null 2>&1 &
					disown
					printf '%s' "$target_session" > "$DEVTERM_SESSION_FILE"
				fi

				# One-way show, not a toggle -- only fire if the special
				# workspace isn't already the visible one, so repeated
				# calls never accidentally hide it. specialWorkspace.name
				# is "" when hidden, "special:dev" when shown (confirmed
				# live).
				local current_special
				current_special=$(hyprctl monitors -j | jq -r '.[0].specialWorkspace.name')
				if [ "$current_special" != "special:dev" ]; then
					hyprctl dispatch 'hl.dsp.workspace.toggle_special("dev")' >/dev/null 2>&1 || true
				fi
			}

			# write_state <category> <name> <project_root> <repo_path> --
			# shared by `set` and `create` (which already knows
			# category/name directly rather than needing to parse them
			# back out of a path).
			write_state() {
				local category="$1" name="$2" project_root="$3" repo_path="$4"
				local rel="$category/$name"

				local tmp
				tmp=$(mktemp)
				jq -nc --arg category "$category" --arg name "$name" \
					--arg project_root "$project_root" --arg repo_path "$repo_path" \
					'{category:$category, name:$name, project_root:$project_root, repo_path:$repo_path}' > "$tmp"
				mv "$tmp" "$STATE_FILE"

				# Keep ~/projects/current-project (a real symlink some
				# shell workflows already reach for directly) pointed at
				# the same project as state.json. Relative target, -sfn
				# not just -sf -- current-project already exists as a
				# symlink-to-directory, and plain `ln -s` against an
				# existing symlink-to-dir places the new link *inside*
				# that directory instead of replacing it; -n is what makes
				# it overwrite in place.
				ln -sfn "$rel" "$PROJECTS_DIR/current-project"
			}

			cmd="''${1:-}"
			case "$cmd" in
				list-languages)
					# One line per devenv preset -- matches
					# src/popups/Picker.qml's languageListProc, which
					# expects {label, language} per line, same shape
					# `list` already uses for {label, path}. Drives the
					# language picker directly off whatever's actually in
					# DEVENVS_DIR, so adding/removing a preset there is
					# the only change needed to add/remove a picker
					# option too -- see DEVENVS_DIR's own comment above
					# for why that's a live symlink, not a store copy.
					# "none" has no file (it means "write nothing") so
					# it's appended as a synthetic entry instead.
					find -L "$DEVENVS_DIR" -maxdepth 1 -name '*.nix' 2>/dev/null \
						| sort \
						| while read -r preset_path; do
							language="$(basename "$preset_path" .nix)"
							# A leading "# label: <text>" comment in the
							# preset file overrides the default
							# capitalized-filename label -- lets a
							# preset's own display name (e.g.
							# "JavaScript/TypeScript" for javascript.nix)
							# live right next to the config it describes,
							# rather than needing a second place to edit.
							label=$(sed -n 's/^# label: //p' "$preset_path" | head -n1)
							if [ -z "$label" ]; then
								label="$(printf '%s' "$language" | sed 's/^./\U&/')"
							fi
							jq -nc --arg label "$label" --arg language "$language" '{label:$label, language:$language}'
						done
					jq -nc '{label:"None", language:"none"}'
					;;
				list)
					# One line per project's repo dir -- matches
					# src/popups/Picker.qml's contextListProc, which
					# expects {label, path} per line. -L: a project's
					# "repo" is sometimes a symlink (see header comment),
					# and plain -type d only matches the link itself, not
					# what it resolves to, without it.
					find -L "$PROJECTS_DIR" -mindepth 3 -maxdepth 3 -type d -name repo 2>/dev/null \
						| sort \
						| while read -r repo_path; do
							rel="''${repo_path#"$PROJECTS_DIR"/}"
							label="''${rel%/repo}"
							jq -nc --arg label "$label" --arg path "$repo_path" '{label:$label, path:$path}'
						done
					;;
				set)
					repo_path="''${2:?usage: syland-context set <repo_path>}"
					# Walks back up from <PROJECTS_DIR>/<category>/<name>/repo.
					project_root=$(dirname "$repo_path")
					rel="''${project_root#"$PROJECTS_DIR"/}"
					category="''${rel%%/*}"
					name="''${rel#*/}"

					write_state "$category" "$name" "$project_root" "$repo_path"
					open_devterm "$repo_path" "$category" "$name"
					;;
				create)
					category="''${2:?usage: syland-context create <category> <name> <language>}"
					name="''${3:?usage: syland-context create <category> <name> <language>}"
					language="''${4:?usage: syland-context create <category> <name> <language>}"

					# category/name must be single safe path components --
					# they're joined directly into $PROJECTS_DIR below.
					case "$category" in */*|.|..|"") echo "syland-context: invalid category '$category'" >&2; exit 1 ;; esac
					case "$name" in */*|.|..|"") echo "syland-context: invalid name '$name'" >&2; exit 1 ;; esac

					project_root="$PROJECTS_DIR/$category/$name"
					repo_path="$project_root/repo"

					if [ -e "$project_root" ]; then
						echo "syland-context: $project_root already exists" >&2
						exit 1
					fi

					mkdir -p "$project_root/documents" "$repo_path"
					# git init'ing the new repo dir is a deliberate default
					# for every new project created this way, not an
					# incidental side effect -- same spirit as always
					# creating documents/ alongside it.
					git -C "$repo_path" init -q

					# Hand-authored devenv.nix per language, copied verbatim
					# from DEVENVS_DIR -- not `devenv init`'s own
					# generated output, and not generated inline here
					# either, so adding/editing a preset is just
					# adding/editing a file under
					# home/syland-context-devenvs/, no shell-script
					# changes needed.
					if [ "$language" != "none" ]; then
						if [ ! -f "$DEVENVS_DIR/$language.nix" ]; then
							# -L: DEVENVS_DIR is itself a symlink to the repo
						# (see its own comment above) -- plain find
						# wouldn't traverse into it at all, same reason
						# `list` above already needs -L for symlinked repo
						# dirs.
						available=$(find -L "$DEVENVS_DIR" -maxdepth 1 -name '*.nix' -printf '%f\n' 2>/dev/null | sed 's/\.nix$//' | sort | tr '\n' ' ')
							echo "syland-context: unknown language '$language' -- no $DEVENVS_DIR/$language.nix preset (available: ''${available}none)" >&2
							exit 1
						fi
						cp "$DEVENVS_DIR/$language.nix" "$repo_path/devenv.nix"
						printf 'use devenv\n' > "$repo_path/.envrc"
					fi

					write_state "$category" "$name" "$project_root" "$repo_path"
					open_devterm "$repo_path" "$category" "$name"
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
							open_devterm "$repo_path" "$(jq -r .category "$STATE_FILE")" "$(jq -r .name "$STATE_FILE")"
							;;
						*)
							echo "usage: syland-context open {pdf|docs|project}" >&2
							exit 1
							;;
					esac
					;;
				toggle-devterm)
					# The symmetric toggle SUPER+ALT+0 (home/hypr/keybinds.lua)
					# calls -- unlike open_devterm's own one-way "show", this
					# one actually hides the special workspace when the
					# devterm window is already open, already showing the
					# current project's own session, and already visible.
					require_state
					category=$(jq -r .category "$STATE_FILE")
					name=$(jq -r .name "$STATE_FILE")
					repo_path=$(jq -r .repo_path "$STATE_FILE")
					target_session=$(session_name_for "$category" "$name")

					existing_pid=$(hyprctl clients -j | jq -r --arg class "$DEV_CLASS" '.[] | select(.class == $class) | .pid' | head -n1)
					current_session=""
					[ -f "$DEVTERM_SESSION_FILE" ] && current_session=$(cat "$DEVTERM_SESSION_FILE")
					current_special=$(hyprctl monitors -j | jq -r '.[0].specialWorkspace.name')

					if [ -n "$existing_pid" ] && [ "$current_session" = "$target_session" ] && [ "$current_special" = "special:dev" ]; then
						hyprctl dispatch 'hl.dsp.workspace.toggle_special("dev")' >/dev/null 2>&1 || true
					else
						open_devterm "$repo_path" "$category" "$name"
					fi
					;;
				current)
					if [ -f "$STATE_FILE" ]; then
						cat "$STATE_FILE"
					else
						echo '{}'
					fi
					;;
				*)
					echo "usage: syland-context {list|list-languages|set <repo_path>|create <category> <name> <language>|open {pdf|docs|project}|toggle-devterm|current}" >&2
					exit 1
					;;
			esac
		'';
	};
in {
	home.packages = [ sylandContext ];
	# A live symlink to the repo, not copied into the store -- see
	# DEVENVS_DIR's own comment above for why that matters (editing a
	# preset here takes effect immediately, no rebuild).
	home.file.".config/syland/context/devenvs".source = ./syland-context-devenvs;
}

# syland-context: finishes the project-switching/docs-reading scaffolding
# that's already sitting in home/hypr/keybinds.lua (SUPER+C/P/ALT+P call
# `syland-context switch`/`open pdf`/`open notes`, but nothing implementing
# it existed until now -- same situation syland-theme-apply was in before
# it got built).
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
		runtimeInputs = [ pkgs.fzf pkgs.jq pkgs.findutils pkgs.coreutils pkgs.gnused pkgs.zellij pkgs.zathura pkgs.ghostty ];
		text = ''
			PROJECTS_DIR="$HOME/projects"
			STATE_DIR="$HOME/.config/syland/context"
			STATE_FILE="$STATE_DIR/state.json"
			mkdir -p "$STATE_DIR"

			require_state() {
				if [ ! -f "$STATE_FILE" ]; then
					echo "syland-context: no active project -- run 'syland-context switch' first" >&2
					exit 1
				fi
			}

			cmd="''${1:-}"
			case "$cmd" in
				switch)
					# category/name dirs, e.g. "work/SeaR" -- matches the
					# real ~/projects/<category>/<name>/{documents,repos}
					# convention already in use.
					project=$(find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d \
						| sed "s#^$PROJECTS_DIR/##" \
						| sort \
						| fzf --prompt="project> " --select-1 --exit-0)
					[ -n "$project" ] || exit 0
					category="''${project%%/*}"
					name="''${project#*/}"
					project_root="$PROJECTS_DIR/$project"

					mapfile -t repos < <(find "$project_root/repos" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
					case "''${#repos[@]}" in
						0)
							echo "syland-context: no repos/ found under $project_root" >&2
							exit 1
							;;
						1)
							repo_path="''${repos[0]}"
							;;
						*)
							repo_path=$(printf '%s\n' "''${repos[@]}" | fzf --prompt="repo> ")
							[ -n "$repo_path" ] || exit 0
							;;
					esac

					tmp=$(mktemp)
					jq -nc --arg category "$category" --arg name "$name" \
						--arg project_root "$project_root" --arg repo_path "$repo_path" \
						'{category:$category, name:$name, project_root:$project_root, repo_path:$repo_path}' > "$tmp"
					mv "$tmp" "$STATE_FILE"

					# Idempotent whether or not a "dev" zellij session
					# already exists: `attach --create` attaches if it's
					# already running, creates it (using config.kdl's own
					# default_layout = "dev") otherwise. NOTE: plain
					# `--session NAME` is NOT for attaching to an existing
					# session -- its own --help says it "specifies the
					# name of a *new* session"; attaching-or-creating is
					# specifically what `attach --create` does (confirmed
					# live: `--session dev --layout dev` alone produced a
					# "There is no active session!" error instead).
					# Ghostty's own `detect` single-instance logic disables
					# single-instance mode whenever CLI args are passed
					# (confirmed in its own docs), so this always spawns a
					# genuinely separate, fresh process -- never proxied to
					# the long-running shared terminal instance the plain
					# "open terminal" keybind uses.
					ghostty -e sh -c "cd '$repo_path' && exec zellij attach --create dev" >/dev/null 2>&1 &
					disown
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
						*)
							echo "usage: syland-context open {pdf|notes|docs}" >&2
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
					echo "usage: syland-context {switch|open {pdf|notes|docs}|current}" >&2
					exit 1
					;;
			esac
		'';
	};
in {
	home.packages = [ sylandContext ];
}

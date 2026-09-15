# syland-todo: Taskwarrior-backed TODO system, sibling to syland-context.nix.
# Reuses that module's ~/.config/syland/context/state.json (category, name)
# as the source of "current project" — there's no separate symlink, that's
# genuinely how syland-context already tracks it — mapped onto
# Taskwarrior's native dot-hierarchy project field as "<category>.<name>"
# (e.g. "work.SeaR"). Tasks with no project set are the always-visible
# "general" list; no extra tag dimension needed since project: alone
# already carries the one piece of context that matters here.
{ pkgs, ... }:
let
	sylandTodo = pkgs.writeShellApplication {
		name = "syland-todo";
		runtimeInputs = [ pkgs.taskwarrior3 pkgs.jq pkgs.coreutils ];
		text = ''
			STATE_FILE="$HOME/.config/syland/context/state.json"

			current_project() {
				if [ -f "$STATE_FILE" ]; then
					jq -r '"\(.category).\(.name)"' "$STATE_FILE" 2>/dev/null || true
				fi
			}

			cmd="''${1:-}"
			case "$cmd" in
				list)
					project=$(current_project)
					if [ -n "$project" ]; then
						# Printed even if the project has zero pending
						# tasks -- otherwise the panel would have no way
						# to know a project is active (and show its name)
						# once its task list is empty.
						jq -nc --arg project "$project" '{scope: "context-header", project: $project}'
						# VERIFY: not runnable in this sandbox (no `task`
						# binary here) -- confirm live once this is
						# deployed, in particular that a bare "project:"
						# filter below really does mean "unset", not
						# "literal empty string" vs erroring.
						task "project:$project" status:pending export 2>/dev/null \
							| jq -c '.[] | {uuid, description, due, project, scope: "context"}'
					fi
					task "project:" status:pending export 2>/dev/null \
						| jq -c '.[] | {uuid, description, due, project, scope: "general"}'
					;;
				add)
					shift
					desc="''${1:?usage: syland-todo add \"<description>\" [--general] [--recur daily|weekly|monthly] [--due <expr>]}"
					shift

					project=$(current_project)
					recur=""
					due=""
					while [ $# -gt 0 ]; do
						case "$1" in
							--general) project="" ;;
							--recur) recur="''${2:?--recur needs a value}"; shift ;;
							--due) due="''${2:?--due needs a value}"; shift ;;
							*) echo "syland-todo: unknown flag $1" >&2; exit 1 ;;
						esac
						shift
					done

					if [ -n "$recur" ] && [ -z "$due" ]; then
						echo "syland-todo: --recur requires --due -- taskwarrior needs a due date to anchor recurrence" >&2
						exit 1
					fi

					args=("$desc")
					[ -n "$project" ] && args+=("project:$project")
					[ -n "$due" ] && args+=("due:$due")
					[ -n "$recur" ] && args+=("recur:$recur")
					task rc.confirmation=off add "''${args[@]}"
					;;
				done)
					uuid="''${2:?usage: syland-todo done <uuid>}"
					task rc.confirmation=off "$uuid" done
					;;
				sync)
					task sync
					;;
				*)
					echo "usage: syland-todo {list|add \"<description>\" [--general] [--recur daily|weekly|monthly] [--due <expr>]|done <uuid>|sync}" >&2
					exit 1
					;;
			esac
		'';
	};
in {
	home.packages = [ sylandTodo ];

	# Explicit rather than relying on taskwarrior3's XDG autodetection
	# (unverified in this sandbox -- no `task` binary to check against) --
	# one line removes the ambiguity entirely.
	home.sessionVariables.TASKRC = "$HOME/.config/task/taskrc";

	home.file.".config/task/taskrc".text = ''
		# Taskwarrior 3.x config -- managed by home-manager, see
		# home/syland-todo.nix. Not the place for secrets (this repo has
		# no sops-nix/agenix), see the sync block below.

		# syland-todo runs `task` non-interactively -- recurring-task
		# regeneration must never block on a y/n prompt.
		recurrence.confirmation=no

		# Sync (and effectively backup) via a self-hosted
		# taskchampion-sync-server on a separate VPS. Once that server
		# exists, create ~/.task-sync.rc by hand (outside this repo, never
		# committed) containing:
		#   sync.server.url=https://<vps-host>:<port>
		#   sync.server.client_id=<uuid>
		#   sync.encryption_secret=<secret>
		# then uncomment the include below.
		# include ~/.task-sync.rc
	'';
}

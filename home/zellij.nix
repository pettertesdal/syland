{ ... }:

{
	programs.zellij = {
		enable = true;
		# `eval "$(zellij setup --generate-auto-start zsh)"` in zsh's init --
		# itself guarded so it never fires from inside an already-running
		# zellij pane, so opening a terminal from within one never nests.
		enableZshIntegration = true;

		settings.default_layout = "dev";

		layouts.dev = ''
			layout {
			    default_tab_template {
			        pane size=1 borderless=true { plugin location="zellij:tab-bar" }
			        children
			        pane size=2 borderless=true { plugin location="zellij:status-bar" }
			    }
			    tab name="editor" focus=true { pane command="nvim" }
			    tab name="shell" { pane }
			}
		'';
	};
}

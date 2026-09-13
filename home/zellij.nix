{ ... }:

{
  programs.zellij = {
    enable = true;

    # Deliberately NOT setting settings.default_layout = "dev" here:
    # that applies globally, including to the plain auto-attach
    # session every new terminal gets via enableZshIntegration above
    # -- confirmed live, it meant SUPER+RETURN's ordinary terminal
    # was launching nvim/the dev tabs too. The "dev" layout is only
    # ever requested explicitly now, by
    # home/syland-context.nix's ensure_devterm, via
    # `--new-session-with-layout dev` at the point it creates that
    # one specific session.

    # KDL, not Nix: inline child nodes inside { } need a trailing ";"
    # or zellij's own parser rejects the whole file (confirmed live --
    # the version without semicolons failed with "Failed to parse
    # Zellij configuration" pointing at the plugin nodes).
    layouts.dev = ''
      			layout {
      			    default_tab_template {
      			        pane size=1 borderless=true { plugin location="zellij:tab-bar"; }
      			        children
      			        pane size=2 borderless=true { plugin location="zellij:status-bar"; }
      			    }
      			    tab name="editor" focus=true { pane command="nvim"; }
      			    tab name="shell" { pane; }
      			}
      		'';
  };
}

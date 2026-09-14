{ pkgs, nvf, ... }:
let
  configModule = {
    config.vim = {
      viAlias = false;
      vimAlias = true;

      git.enable = true;

      utility.oil-nvim = {
        enable = true;
        gitStatus.enable = true;
      };

      luaConfigRC.syland-theme = ''
        dofile("${./nvim/syland-theme.lua}")
      '';

      options = {
        # The rendered length
        tabstop = 2;
        # The length you indent with >>
        shiftwidth = 2;
      };

      binds.whichKey.enable = true;
      fzf-lua.enable = true; # reuses the fzf binary already installed via programs.fzf
      statusline.lualine.enable = true;
      treesitter.enable = true;
      autocomplete.nvim-cmp.enable = true;

      lsp = {
        enable = true;
        formatOnSave = true;
      };

      languages = {
        nix.enable = true;
        markdown = {
          enable = true;
          extensions.render-markdown-nvim.enable = true;
        };
        csharp.enable = true; # DscSimulation and future .NET work
      };

      # claudecode.nvim: implements the real WebSocket/MCP protocol
      # Claude Code's official IDE integrations use (writes
      # ~/.claude/ide/*.lock, the `claude` CLI -- already installed
      # via programs.claude-code in home/shell.nix -- auto-connects
      # to it). Live selection/file/cursor context sync and native
      # diffs, not just a terminal wrapper. Depends on snacks.nvim.
      extraPlugins = {
        snacks-nvim = {
          package = pkgs.vimPlugins.snacks-nvim;
          setup = "require('snacks').setup({})";
        };
        claudecode-nvim = {
          package = pkgs.vimPlugins.claudecode-nvim;
          setup = "require('claudecode').setup({})";
          after = [ "snacks-nvim" ];
        };
      };

      # Claude keymaps taken from claudecode.nvim's own README.
      keymaps = [
        {
          key = "<leader>ac";
          mode = "n";
          desc = "Toggle Claude";
          action = "<cmd>ClaudeCode<cr>";
        }
        {
          key = "<leader>af";
          mode = "n";
          desc = "Focus Claude";
          action = "<cmd>ClaudeCodeFocus<cr>";
        }
        {
          key = "<leader>ab";
          mode = "n";
          desc = "Add current buffer";
          action = "<cmd>ClaudeCodeAdd %<cr>";
        }
        {
          key = "<leader>as";
          mode = "v";
          desc = "Send selection";
          action = "<cmd>ClaudeCodeSend<cr>";
        }
        {
          key = "<leader>aa";
          mode = "n";
          desc = "Accept Claude diff";
          action = "<cmd>ClaudeCodeDiffAccept<cr>";
        }
        {
          key = "<leader>ad";
          mode = "n";
          desc = "Deny Claude diff";
          action = "<cmd>ClaudeCodeDiffDeny<cr>";
        }
        {
          key = "<leader>tt";
          mode = "n";
          lua = true;
          desc = "Run project tests (devenv test)";
          action = ''function() vim.cmd("botright 15split | terminal devenv test") vim.cmd("startinsert") end'';
        }
        {
          key = "<leader>e";
          mode = "n";
          desc = "File explorer";
          action = "<cmd>Oil<cr>";
        }
        {
          key = "<leader>ff";
          mode = "n";
          desc = "File files";
          action = "<cmd>FzfLua files<cr>";
        }
        {
          key = "<leader>gh";
          mode = "n";
          desc = "Toggle git hunk signs";
          lua = true;
          action = "function() require('gitsigns').toggle_signs() end";
        }
        {
          # Fugitive keybinds
          key = "<leader>gs";
          mode = "n";
          desc = "Git status";
          action = "<cmd>Git<cr>";
        }
        {
          key = "<leader>gd";
          mode = "n";
          desc = "Diff current file against index";
          action = "<cmd>Gvdiffsplit<cr>";
        }
        {
          key = "<leader>gl";
          mode = "n";
          desc = "File history log";
          action = "<cmd>Gclog<cr>";
        }
        {
          key = "<leader>gp";
          mode = "n";
          desc = "Git push";
          action = "<cmd>Git push<cr>";
        }
        {
          key = "<leader>gP";
          mode = "n";
          desc = "Git pull";
          action = "<cmd>Git pull<cr>";
        }
      ];
    };
  };

  customNeovim = nvf.lib.neovimConfiguration {
    inherit pkgs; # reuse the already-pinned global pkgs, not a second nixpkgs evaluation
    modules = [ configModule ];
  };
in
{
  home.packages = [ customNeovim.neovim ];
  # The standalone installation route has no defaultEditor convenience
  # option (that's specific to nvf's home-manager-module mode), so set
  # it explicitly.
  home.sessionVariables.EDITOR = "nvim";
}

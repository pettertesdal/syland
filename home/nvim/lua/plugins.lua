-- Add real plugins here as you build out your config.
-- mason.nvim is included from the start since it's how LSP/formatter/linter
-- tooling stays portable across distros (see design doc Section 14).
return {
  { "neovim/nvim-lspconfig" },
  {
    "williamboman/mason.nvim",
    config = function() require("mason").setup() end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
  },
}

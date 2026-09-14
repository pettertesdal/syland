local path = os.getenv("HOME") .. "/.config/syland/themes/nvim.generated.lua"
local ok, palette = pcall(dofile, path)
if not ok then return end

local transparent = true

local hl = vim.api.nvim_set_hl
local bg = transparent and "none" or palette.background

hl(0, "Normal", { fg = palette.foreground, bg = bg })
hl(0, "NormalFloat", { fg = palette.foreground, bg = bg })
hl(0, "SignColumn", { bg = bg })
hl(0, "EndOfBuffer", { bg = bg })
hl(0, "Comment", { fg = palette.comment, italic = true })
hl(0, "LineNr", { fg = palette.comment })
hl(0, "CursorLine", { bg = palette.cursorline })
hl(0, "CursorLineNr", { fg = palette.accent, bold = true })
hl(0, "Visual", { bg = palette.visual })
hl(0, "Search", { bg = palette.yellow, fg = palette.background })
hl(0, "IncSearch", { bg = palette.accent, fg = palette.background })
hl(0, "Pmenu", { fg = palette.foreground, bg = palette.pmenu })
hl(0, "PmenuSel", { bg = palette.pmenu_sel })

hl(0, "Identifier", { fg = palette.foreground })
hl(0, "Function", { fg = palette.accent, bold = true })
hl(0, "Keyword", { fg = palette.accent })
hl(0, "Statement", { fg = palette.accent })
hl(0, "String", { fg = palette.green })
hl(0, "Constant", { fg = palette.yellow })
hl(0, "Number", { fg = palette.yellow })
hl(0, "Type", { fg = palette.yellow })
hl(0, "Special", { fg = palette.accent })
hl(0, "Error", { fg = palette.red, bold = true })

hl(0, "DiagnosticError", { fg = palette.red })
hl(0, "DiagnosticWarn", { fg = palette.yellow })
hl(0, "DiagnosticInfo", { fg = palette.accent })
hl(0, "DiagnosticHint", { fg = palette.comment })

hl(0, "DiffAdd", { bg = palette.diff_add })
hl(0, "DiffDelete", { bg = palette.diff_delete })
hl(0, "DiffChange", { bg = palette.diff_change })

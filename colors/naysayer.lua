-- Vendored naysayer palette, kept deliberately flat with prominent comments.

local c = {
  background = "#062625",
  gutter = "#062625",
  selection = "#0000ff",
  text = "#d0b892",
  comment = "#53d549",
  punctuation = "#8cde94",
  keyword = "#ffffff",
  string = "#3ad0b5",
  constant = "#87ffde",
  macro = "#8cde94",
  white = "#ffffff",
  error = "#ff0000",
  warning = "#ffaa00",
  highlight = "#0b3335",
  line_fg = "#126367",
  status_fg = "#12251b",
  status_bg = "#d3b58e",
  -- Accents are reserved for diagnostics and other state.
  orange = "#FD971F",
  red = "#F92672",
  blue = "#66D9EF",
  cyan = "#A1EFE4",
}

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "naysayer"

local set = vim.api.nvim_set_hl

-- Core UI
set(0, "Normal", { fg = c.text, bg = c.background })
set(0, "NormalFloat", { fg = c.text, bg = c.highlight })
set(0, "FloatBorder", { fg = c.line_fg, bg = c.highlight })
set(0, "Cursor", { bg = c.white })
set(0, "Visual", { bg = c.selection })
set(0, "LineNr", { fg = c.line_fg, bg = c.background })
set(0, "CursorLineNr", { fg = c.white, bg = c.background })
set(0, "CursorLine", { bg = c.highlight })
set(0, "ColorColumn", { bg = c.highlight })
set(0, "WinSeparator", { fg = c.line_fg })
set(0, "MatchParen", { bg = c.selection })
set(0, "SignColumn", { bg = c.background })
set(0, "Folded", { fg = c.line_fg, bg = c.highlight })
set(0, "NonText", { fg = c.line_fg })
set(0, "Whitespace", { fg = c.line_fg })
set(0, "Search", { fg = c.status_fg, bg = c.status_bg })
set(0, "IncSearch", { fg = c.status_fg, bg = c.warning })
set(0, "Directory", { fg = c.constant })
set(0, "Title", { fg = c.white })

-- Define only groups that differ from their inherited parent. Character,
-- Operator, and Delimiter are explicit because their default links are unsuitable.
set(0, "Comment", { fg = c.comment })
set(0, "String", { fg = c.string })
set(0, "Character", { fg = c.string })
set(0, "Constant", { fg = c.constant })
set(0, "Identifier", { fg = c.text })
set(0, "Function", { fg = c.text })
set(0, "Statement", { fg = c.keyword })
set(0, "Operator", { fg = c.text })
set(0, "Type", { fg = c.punctuation })
set(0, "PreProc", { fg = c.macro })
set(0, "Special", { fg = c.orange })
set(0, "Delimiter", { fg = c.text })
set(0, "Todo", { fg = c.background, bg = c.comment, bold = true })

-- Messages and diagnostics.
set(0, "WarningMsg", { fg = c.warning })
set(0, "ErrorMsg", { fg = c.error })
set(0, "Error", { fg = c.error })
set(0, "DiagnosticError", { fg = c.red })
set(0, "DiagnosticWarn", { fg = c.warning })
set(0, "DiagnosticInfo", { fg = c.blue })
set(0, "DiagnosticHint", { fg = c.cyan })
set(0, "DiagnosticUnderlineError", { sp = c.red, undercurl = true })
set(0, "DiagnosticUnderlineWarn", { sp = c.warning, undercurl = true })

-- Completion menu.
set(0, "Pmenu", { fg = c.text, bg = c.highlight })
set(0, "PmenuSel", { fg = c.status_fg, bg = c.status_bg })
set(0, "PmenuSbar", { bg = c.highlight })
set(0, "PmenuThumb", { bg = c.line_fg })

-- Status line.
set(0, "StatusLine", { fg = c.status_fg, bg = c.status_bg })
set(0, "StatusLineNC", { fg = c.line_fg, bg = c.gutter })

return c

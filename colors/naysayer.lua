-- naysayer -- Jonathan Blow's Emacs colours, vendored.
--
--  Lineage: Blow's hand-rolled Emacs theme -> nickav/naysayer-theme.el (eyeballed
--  off his compiler livestreams) -> RostislavArts/naysayer.nvim -> this file. The
--  palette below is copied verbatim from that port; what is *not* copied is its
--  set of `@`-prefixed treesitter groups, which used the Monokai accent colours
--  and made it noticeably louder than the Emacs original. The port's own README
--  admits as much: treesitter disabled is "most accurate to Jon's theme".
--
--  The idea worth preserving: syntax highlighting is almost off. Functions and
--  variables are the same tan as ordinary text, keywords are plain white, and the
--  single brightest thing on screen is the comments -- the prose a human wrote.
--  That is the opposite of a typical theme, where comments are dimmed to grey.
--
--  This is a real colorscheme file rather than a plugin, so `:colorscheme
--  naysayer` finds it on the runtimepath and re-sources it on every switch. The
--  plugin needed a `ColorSchemePre` hook to drop `package.loaded` because it
--  applied itself at module scope and `require` cached it; a colors/ file has no
--  such problem.

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
  -- The mode line: dark ink on tan. Blow's is one flat bar and so is this.
  status_fg = "#12251b",
  status_bg = "#d3b58e",
  -- Accents, used only where something must stand out as a *state* rather than
  --  as syntax: diagnostics and Special.
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

-- Syntax. Deliberately flat: `Identifier` and `Function` are the same colour as
--  `Normal`, so neither variables nor calls are picked out from the text around
--  them. If you ever want them distinguished, this is the pair to change.
--
--  Only groups that need to *differ* from their parent are listed. Vim already
--  links Number/Boolean/Float to Constant, Conditional/Repeat/Exception/Keyword to
--  Statement, StorageClass/Structure/Typedef to Type, and Include/Define/Macro to
--  PreProc -- defining those again with the parent's own colour changes nothing.
--  Three break that rule on purpose and must stay: `Character`, because a char
--  literal reads as a string rather than a constant; and `Operator` and
--  `Delimiter`, which Vim links to *nothing* -- drop them and they fall through to
--  Neovim's stock foreground rather than to the `Normal` defined here.
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

-- Messages and diagnostics. These are states, not syntax, so they are the one
--  place colour is allowed to shout.
set(0, "WarningMsg", { fg = c.warning })
set(0, "ErrorMsg", { fg = c.error })
set(0, "Error", { fg = c.error })
set(0, "DiagnosticError", { fg = c.red })
set(0, "DiagnosticWarn", { fg = c.warning })
set(0, "DiagnosticInfo", { fg = c.blue })
set(0, "DiagnosticHint", { fg = c.cyan })
set(0, "DiagnosticUnderlineError", { sp = c.red, undercurl = true })
set(0, "DiagnosticUnderlineWarn", { sp = c.warning, undercurl = true })

-- Completion menu (built-in `ins-completion`; there is no completion plugin).
set(0, "Pmenu", { fg = c.text, bg = c.highlight })
set(0, "PmenuSel", { fg = c.status_fg, bg = c.status_bg })
set(0, "PmenuSbar", { bg = c.highlight })
set(0, "PmenuThumb", { bg = c.line_fg })

-- Status line. One flat bar: `StatusLine` for the focused window, and the
--  receding `StatusLineNC` for the others.
set(0, "StatusLine", { fg = c.status_fg, bg = c.status_bg })
set(0, "StatusLineNC", { fg = c.line_fg, bg = c.gutter })

return c

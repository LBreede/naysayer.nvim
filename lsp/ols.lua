-- OLS, the Odin language server.
--
--  Install `ols` so it is on $PATH. It needs the `builtin/` folder from the
--  OLS repo next to the binary, or `OLS_BUILTIN_FOLDER` set to that directory.
--  Project collections and checker paths belong in an `ols.json` at the
--  workspace root, so Neovim stays generic.
return {
  cmd = { "ols" },
  filetypes = { "odin" },
  root_markers = { "ols.json", "odin.json", ".git" },
  init_options = {
    enable_format = true,
    enable_hover = true,
    enable_document_symbols = true,
    enable_references = true,
    enable_snippets = true,
  },
}

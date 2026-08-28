-- clangd. Neovim ships no server configs of its own, so this file *is* the
--  config: `vim.lsp.enable 'clangd'` in init.lua finds it by name on the
--  runtimepath. No nvim-lspconfig, no mason.
--
--  NOTE: clangd needs the compile flags to resolve includes. It looks upward for
--  `compile_commands.json` (emit one with `cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
--  or `bear -- make`) and falls back to `compile_flags.txt`, one flag per line.
--  Without either it guesses, and C++ headers go red.
--
--  Whichever clangd is first on $PATH wins: /usr/bin/clangd is 17.x, a rez env
--  may provide a newer one.
return {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
}

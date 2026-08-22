-- basedpyright -- a community fork of pyright with stricter defaults and extra
--  Pylance-style features (inlay hints, semantic tokens).
--
--  NOTE: not provided by rez and no longer installed by mason. Install it once:
--    pip install --user basedpyright
--  It lands in ~/.local/bin, which must be on $PATH. If the binary is missing the
--  server simply never attaches -- `vim.lsp.enable` does not error on that.
return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  settings = {
    basedpyright = {
      analysis = {
        -- basedpyright defaults to a far stricter mode than pyright, which floods
        --  a typical codebase. 'standard' is what pyright would have given you.
        typeCheckingMode = "standard",
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          functionReturnTypes = true,
          genericTypes = false,
        },
      },
    },
  },
}


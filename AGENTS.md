# AGENTS.md

## Branch Model

`master` is the barebones Neovim config. Keep it plugin-free and focused on
native Neovim features.

`local` is a long-lived daily-driver overlay. It may contain `after/`, `lsp/`,
`vim.pack` plugins, and `nvim-pack-lock.json`. It is not meant to be merged
back into `master`.

When `master` changes, rebase `local` onto it:

```sh
git checkout local
git rebase master
git push --force-with-lease
```

Do not rebase or merge `master` because of local-only changes.

## File Ownership

Belongs on `master`:

- `init.lua`
- `colors/`
- `stylua.toml`
- `README.md`
- `.gitignore`
- `AGENTS.md`

Belongs on `local`:

- `after/`
- `lsp/`
- `nvim-pack-lock.json`

## Style

Prefer native Neovim features over plugins. Plugins are allowed only on `local`
when they replace nontrivial hand-rolled behavior.

Use `stylua` for Lua files.

# AGENTS.md

## Repository Model

`master` is the standalone, plugin-free Neovim config. Personal daily-driver
configuration belongs in a separate repository that loads this one as a
submodule.

## File Ownership

- `init.lua`
- `colors/`
- `stylua.toml`
- `.editorconfig`
- `README.md`
- `.gitignore`
- `AGENTS.md`

## Style

Prefer native Neovim features. Plugins and personal overrides do not belong in
this repository.

Use `stylua` for Lua files.

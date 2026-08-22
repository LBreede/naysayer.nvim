# naysayer.nvim

A small Neovim config inspired by Jonathan Blow's Emacs setup: quiet syntax,
no plugin machinery in the base branch, native editor features first, and local
preferences layered on top instead of mixed into the core.

## Install

Back up any existing Neovim config, state, and data first:

```sh
stamp="$(date +%Y%m%d-%H%M%S)"
test -e "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" && mv "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim.bak-$stamp"
test -e "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" && mv "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" "${XDG_STATE_HOME:-$HOME/.local/state}/nvim.bak-$stamp"
test -e "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" && mv "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" "${XDG_DATA_HOME:-$HOME/.local/share}/nvim.bak-$stamp"
```

Clone the repo as Neovim's config directory:

```sh
git clone git@github.com:LBreede/naysayer.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
```

Stay on `master` for the barebones Blow-inspired config:

```sh
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
git checkout master
```

Use `local` for the daily-driver overlay:

```sh
cd "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
git checkout local
```

## Branches

`master` is the barebones config. It contains the base editor setup, the
vendored colorscheme, and formatting rules for the Lua files.

`local` is the daily-driver overlay. It rebases on top of `master` and contains
personal additions such as `after/`, `lsp/`, native package plugins, and the
plugin lockfile. It is not meant to be merged back into `master`.

GitHub may offer to open a pull request for `local`; ignore that prompt. The
branch is an extension branch, not a feature branch waiting to land.

## Layout

```text
init.lua              base config
colors/naysayer.lua   vendored colorscheme
stylua.toml           formatter settings for this repo
after/                local overlay, tracked only on local
lsp/                  local LSP configs, tracked only on local
nvim-pack-lock.json   local vim.pack lockfile
```

## Workflow

Make barebones changes on `master`:

```sh
git checkout master
# edit init.lua, colors/naysayer.lua, stylua.toml, README.md
git add <files>
git commit -m "chore: ..."
git push
```

Then update `local`:

```sh
git checkout local
git rebase master
git push --force-with-lease
```

Make daily-driver changes on `local`:

```sh
git checkout local
# edit after/, lsp/, nvim-pack-lock.json
git add <files>
git commit -m "feat: ..."
git push
```

Do not rebase or merge `master` because of a `local`-only change.

Rule of thumb:

```text
master changes -> rebase local
local changes  -> leave master alone
```

## Commit Types

Use `feat` for new editor behavior:

```text
feat: add Odin language server
feat: add local surround plugin
```

Use `fix` for correcting broken behavior:

```text
fix: use current yank highlight helper
```

Use `chore` for repo hygiene, docs, formatting, and metadata:

```text
chore: add README
chore: ignore Neovim log file
```

Use `refactor` when moving behavior between layers without changing the intent:

```text
refactor: move yank highlight out of base config
```

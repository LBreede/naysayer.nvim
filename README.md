# naysayer.nvim

A small Neovim config inspired by Jonathan Blow's Emacs setup: quiet syntax,
no plugin machinery in the base branch, native editor features first, and local
preferences layered on top instead of mixed into the core.

## Rationale

The base config follows observations from Jonathan Blow's Emacs setup where they
map cleanly to Neovim:

- no line numbers; the statusline is the line indicator
- no file tree, tabs, icons, or visible whitespace markers
- no automatic pair completion for `()`, `{}`, `[]`, or quotes
- quiet syntax highlighting, with comments more prominent than most code
- 4-column hard tabs rather than 8-column tabs or space-expanded indentation
- search and compiler results as lists to walk with native quickfix commands
- a plain statusline similar in spirit: file, position, line, version-control
  state, and filetype

The `local` branch is allowed to diverge for daily use. Plugins and personal UI
preferences belong there when they add practical editing leverage without
changing what the base branch is trying to preserve.

## Install

Back up any existing Neovim config, state, and data first:

```sh
test -e "$HOME/.config/nvim" && mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
test -e "$HOME/.local/state/nvim" && mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak"
test -e "$HOME/.local/share/nvim" && mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak"
```

Clone the repo as Neovim's config directory:

```sh
git clone git@github.com:LBreede/naysayer.nvim.git "$HOME/.config/nvim"
```

Stay on `master` for the barebones Blow-inspired config:

```sh
cd "$HOME/.config/nvim"
git checkout master
```

Use `local` for the daily-driver overlay:

```sh
cd "$HOME/.config/nvim"
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
.editorconfig         editor indent rules, so typing matches stylua
after/                local overlay, tracked only on local
lsp/                  local LSP configs, tracked only on local
nvim-pack-lock.json   local vim.pack lockfile
```

## Workflow

Make barebones changes on `master`:

```sh
git checkout master
# edit init.lua, colors/naysayer.lua, stylua.toml, .editorconfig, README.md
git add <files>
git commit -m "<type>: ..."
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

Use `docs` for documentation-only changes:

```text
docs: update branch workflow notes
docs: clarify install steps
```

Use `chore` for repo hygiene and metadata:

```text
chore: ignore Neovim log file
```

Use `format` when the diff is a formatter's output and nothing was hand-edited:

```text
format: stylua
```

Use `refactor` when moving behavior between layers without changing the intent:

```text
refactor: move yank highlight out of base config
```


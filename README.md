# naysayer.nvim

A small, plugin-free Neovim config inspired by Jonathan Blow's Emacs setup:
quiet syntax and native editor features first.

## Rationale

The base config follows observations from Jonathan Blow's Emacs setup where they
map cleanly to Neovim:

- no line numbers; the statusline is the line indicator
- no file tree, tabs, icons, or visible whitespace markers
- no automatic pair completion for `()`, `{}`, `[]`, or quotes
- quiet syntax highlighting, with comments more prominent than most code
- 4-column space indentation, while literal tabs remain visibly 8 columns wide
- search and compiler results as lists to walk with native quickfix commands
- a plain statusline similar in spirit: file, position, line, version-control
  state, and filetype

Personal plugins and preferences belong in a separate overlay repository, which
can load this repository as a submodule without changing the standalone base.

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

The default `master` branch is the complete standalone config:

```sh
cd "$HOME/.config/nvim"
git checkout master
```

## Layout

```text
init.lua              base config
colors/naysayer.lua   vendored colorscheme
stylua.toml           formatter settings for this repo
.editorconfig         editor indent rules, so typing matches stylua
AGENTS.md              repository ownership and contributor rules
```

## Personal Overlay

To keep personal configuration versioned separately, add this repository as a
submodule named `base` and load it from the overlay's `init.lua`:

```lua
local base = vim.fs.joinpath(vim.fn.stdpath("config"), "base")
vim.opt.runtimepath:prepend(base)
dofile(vim.fs.joinpath(base, "init.lua"))
```

The overlay can then own `after/`, `lsp/`, plugins, and personal options while
this repository remains directly usable on its own.

## Workflow

Make base changes inside the submodule:

```sh
cd "$HOME/.config/nvim/base"
git switch master
# edit base files
git add <files>
git commit -m "<type>: ..."
git push
```

Record the updated base revision in the overlay:

```sh
cd "$HOME/.config/nvim"
git add base
git commit -m "chore: update base config"
git push
```

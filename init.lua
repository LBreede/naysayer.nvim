-- Neovim, shaped after Jonathan Blow's Emacs setup. No plugins at all.
--
--  Not a minimalism stunt -- everything a plugin would have provided is now in
--  Neovim itself: `grepprg` + quickfix replaces a fuzzy finder, `wildoptions=fuzzy`
--  replaces the picker's matching, built-in `ins-completion` replaces the
--  completion popup, and a colorscheme is a file in `colors/`. What is left is
--  configuration, not machinery: no plugin manager, no lock file, nothing to
--  update or lazy-load.
--
--  The shape being copied, from his compiler livestreams:
--   - syntax highlighting almost off, comments the brightest thing on screen
--   - no line numbers, no gutter, no file tree, no tabs, no icons, no animation
--   - a spartan mode line: file, position, line, VC, major mode
--   - results as a list you walk: `:grep` fills quickfix, `]q` steps through it
--
--  This file is the whole editor. To add your own things -- line numbers, a
--  language server, your own keymaps -- put them in `after/plugin/`, which Neovim
--  sources after this file. Options and keymaps are last-write-wins, so such a
--  file reads as a diff against this one, and deleting it gives you this again.

-- ============================================================
-- OPTIONS
-- ============================================================
do
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- Neovim's default, kept explicit: the usual reason to disable it is a statusline
  --  that carries the mode, and this one deliberately has no mode field -- Blow's
  --  has none either, though Emacs gets that for free by being modeless.
  vim.o.showmode = true

  vim.o.undofile = true
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.updatetime = 250
  vim.o.timeoutlen = 300
  vim.o.splitright = true
  vim.o.splitbelow = true
  vim.o.confirm = true -- prompt instead of failing on :q with unsaved changes
  vim.o.scrolloff = 10
  vim.o.inccommand = "split"

  -- Four settings whose defaults are worse than one line of config.
  vim.o.winborder = "single" -- was "": borders on every float
  vim.o.splitkeep = "screen" -- was "cursor": text stops jumping when quickfix opens
  vim.opt.jumpoptions:append("view") -- was "clean": <C-o> restores the view, not just the cursor
  vim.opt.completeopt:append("fuzzy") -- <C-n> matches the way 'wildoptions=fuzzy' already does

  -- Don't wrap. A wrapped line silently costs several rows and breaks the "one
  --  line of code, one row" assumption that makes `10j` reliable.
  --  `:setlocal wrap` per buffer when reading prose.
  vim.o.wrap = false

  -- No cursorline: the cursor already marks the line, and a highlighted band
  --  competes with the syntax colours for attention.
  vim.o.cursorline = false

  vim.o.list = true
  vim.opt.listchars = { tab = "\u{bb} ", trail = "\u{b7}", nbsp = "\u{2423}" }

  vim.cmd.colorscheme("naysayer")
end

-- ============================================================
-- FINDING THINGS -- no picker, no fuzzy finder
-- ============================================================
do
  -- `:grep` shells out to ripgrep and fills the quickfix list; `]q` and `[q` walk
  --  it, and both are Neovim defaults. `:find` searches 'path' recursively, and
  --  'fuzzy' makes its completion menu match the way a picker would --
  --  `:find statln<Tab>` finds `statusline.lua`.
  --
  --  No keymaps here on purpose: the commands are short and the bindings are a
  --  matter of taste. Bind them in `after/plugin/` if you want them.
  --
  --  NOTE: `**` walks the whole tree under the cwd. That is cheap on a local disk
  --  and slow over a network mount at the top of a large tree.
  vim.o.grepprg = "rg --vimgrep --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m"
  vim.opt.path:append("**")
  vim.o.wildoptions = "pum,fuzzy"
  vim.o.wildignorecase = true
  vim.opt.wildignore:append({ "*.o", "*.pyc", "*/__pycache__/*", "*/.git/*", "*/target/*" })

  vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

  -- Open the quickfix window on its own when a search finds something, and close
  --  it when a rerun comes back empty -- a stale list sitting there looks exactly
  --  like a current result.
  vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    desc = "Open quickfix when it has entries",
    group = vim.api.nvim_create_augroup("quickfix", { clear = true }),
    pattern = { "grep", "grepadd", "vimgrep" },
    callback = function()
      vim.cmd(#vim.fn.getqflist() > 0 and "copen" or "cclose")
    end,
  })
end

-- ============================================================
-- STATUSLINE
-- ============================================================
do
  ---The branch name, read straight out of `.git/HEAD` -- no subprocess, ~0.25ms.
  ---Falls back to a short SHA on a detached HEAD, and nil outside a repository.
  ---@param dir string
  ---@return string?
  local function git_branch(dir)
    local git = vim.fs.find(".git", { upward = true, path = dir })[1]
    if not git then
      return nil
    end
    -- In a worktree `.git` is a file containing `gitdir: <path>`, not a directory.
    if vim.fn.isdirectory(git) == 0 then
      local f = io.open(git)
      if not f then
        return nil
      end
      local gitdir = (f:read("l") or ""):match("^gitdir: (.*)$")
      f:close()
      if gitdir then
        git = vim.fs.normalize(gitdir)
      end
    end
    local head = io.open(git .. "/HEAD")
    if not head then
      return nil
    end
    local ref = head:read("l") or ""
    head:close()
    return ref:match("ref: refs/heads/(.+)$") or ref:sub(1, 7)
  end

  -- Cached per buffer: the statusline redraws on every cursor move, the branch
  --  changes about twice a day.
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "DirChanged", "FocusGained" }, {
    desc = "Cache the git branch for the statusline",
    group = vim.api.nvim_create_augroup("statusline-branch", { clear = true }),
    callback = function(args)
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end
      local name = vim.api.nvim_buf_get_name(args.buf)
      vim.b[args.buf].branch = git_branch(name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd())
    end,
  })

  -- Blow's mode line reads `-\---  polymorph.h  Top  L31  SVN:5587  (C/l Abbrev)`.
  --  Same *fields* here -- file, position, line, VC, major mode -- but written in
  --  Vim's vocabulary rather than transliterated from Emacs.
  --
  --  What was dropped as Emacsism, and what replaces it:
  --   - `-\---` / `-\**-`: Emacs packs the coding system, end-of-line convention,
  --     modified and read-only flags into a cryptic four-character prefix. Vim has
  --     `%m` -> `[+]` and `%r` -> `[RO]`, which a Vim user reads without training.
  --   - the eol mnemonic (`:` unix, `\` dos): shown as `[dos]` and only when it is
  --     *not* unix. A field that always reads the same conveys nothing; one that
  --     appears out of nowhere is exactly what you want to notice before a stray
  --     CRLF file lands in a diff as a wall of `^M`. Same for a non-utf-8 encoding.
  --   - `L31`: the `L` prefix is Emacs shorthand. Vim just prints the number.
  --   - `(python)`: Emacs parenthesises major and minor modes together. `%y` gives
  --     `[python]`, which is Vim's own spelling.
  --
  --  `%P` survives untouched: Top/Bot/All/NN% is native to Vim too -- it is what
  --  `'ruler'` has always shown -- so it was never an Emacsism to begin with.
  --
  --  All of it is now a plain 'statusline' string. The only part Vim has no item
  --  for is the branch, which comes from `b:branch` above.
  vim.o.statusline = table.concat({
    " %t%m%r", -- basename, then [+] and [RO] when they apply
    "  %P", -- where the *window* sits in the file, not the cursor
    "  %l",
    [[%{empty(get(b:,'branch',''))?'':'  '.b:branch}]],
    "  %y",
    [[%{&fileformat!='unix'?'  ['.&fileformat.']':''}]],
    [[%{&fileencoding!='' && &fileencoding!='utf-8' ? '  '.&fileencoding : ''}]],
    "%=", -- left-aligned; the rest of the bar stays empty
  })
end

-- ============================================================
-- SMALL THINGS
-- ============================================================
do
  vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Flash the yanked text",
    group = vim.api.nvim_create_augroup("yank-highlight", { clear = true }),
    callback = function()
      vim.hl.on_yank()
    end,
  })

  -- Window navigation without the <C-w> prefix.
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    vim.keymap.set("n", "<C-" .. key .. ">", "<C-w><C-" .. key .. ">", { desc = "Move focus" })
  end

  vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
end

-- vim: ts=2 sts=2 sw=2 et

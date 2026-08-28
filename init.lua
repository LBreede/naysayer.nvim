-- Plugin-free base config, shaped after Jonathan Blow's Emacs setup. Personal
-- additions belong in after/plugin/ on the local branch.

-- ============================================================
-- OPTIONS
-- ============================================================
do
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- The statusline has no mode field.
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

  -- Write four spaces. Keep 'tabstop' at 8 so literal tabs remain conspicuous.
  vim.o.shiftwidth = 4
  vim.o.softtabstop = -1 -- follow 'shiftwidth', so there is one number, not two
  vim.o.expandtab = true

  vim.o.winborder = "single"
  vim.o.splitkeep = "screen"
  vim.opt.jumpoptions:append("view")
  vim.opt.completeopt:append("fuzzy")

  vim.o.wrap = false
  vim.o.cursorline = false

  vim.cmd.colorscheme("naysayer")
end

-- ============================================================
-- FINDING THINGS -- no picker, no fuzzy finder
-- ============================================================
do
  -- :grep fills quickfix; :find searches recursively with fuzzy completion.
  vim.o.grepprg = "rg --vimgrep --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m"
  vim.opt.path:append("**")
  vim.o.wildoptions = "pum,fuzzy"
  vim.o.wildignorecase = true
  vim.opt.wildignore:append({ "*.o", "*.pyc", "*/__pycache__/*", "*/.git/*", "*/target/*" })

  -- Do not leave stale results visible after an empty search.
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
    -- Linked worktrees use a .git file whose path may be relative.
    if vim.fn.isdirectory(git) == 0 then
      local f = io.open(git)
      if not f then
        return nil
      end
      local gitdir = (f:read("l") or ""):match("^gitdir: (.*)$")
      f:close()
      if gitdir then
        git = vim.fs.normalize(gitdir:sub(1, 1) == "/" and gitdir or vim.fs.joinpath(vim.fs.dirname(git), gitdir))
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

  ---Reserved for the local overlay to extend the statusline without copying it.
  ---@return string
  function _G.StatuslineExtra()
    return ""
  end

  vim.o.statusline = table.concat({
    " %t%m%r", -- basename, then [+] and [RO] when they apply
    "  %P", -- where the *window* sits in the file, not the cursor
    "  %l",
    [[%{empty(get(b:,'branch',''))?'':'  '.b:branch}]],
    "  %y",
    [[%{v:lua.StatuslineExtra()}]], -- empty unless an overlay redefines it
    [[%{&fileformat!='unix'?'  ['.&fileformat.']':''}]],
    [[%{&fileencoding!='' && &fileencoding!='utf-8' ? '  '.&fileencoding : ''}]],
    "%=", -- left-aligned; the rest of the bar stays empty
  })
end

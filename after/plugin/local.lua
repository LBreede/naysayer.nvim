--
--  Known cost of the arrangement: the statusline below is a *superset* of the one
--  in `init.lua`, reassigned wholesale, because a format string that has already
--  been assigned cannot be appended to. Those two lists have to be kept in sync
--  by hand -- it is the one place where the split duplicates rather than layers.

-- ============================================================
-- THIS MACHINE
-- ============================================================
do
  -- Your own tools live in ~/.local/bin -- stylua, basedpyright. `rez env` builds
  --  $PATH from scratch and leaves that directory out, so inside a resolve nvim
  --  cannot find them at all, and `<leader>f` on a Lua file fails with "stylua: not
  --  on $PATH" despite stylua being installed.
  --
  --  Appended, never prepended: whatever the resolve provides has to keep priority.
  --  Prepending is exactly the mistake mason made -- its black 26 sat ahead of the
  --  pipeline's black 25 on $PATH and silently reformatted to the wrong standard.
  local user_bin = vim.fs.joinpath(vim.env.HOME, ".local", "bin")
  if not (":" .. (vim.env.PATH or "") .. ":"):find(":" .. user_bin .. ":", 1, true) then
    vim.env.PATH = (vim.env.PATH or "") .. ":" .. user_bin
  end
end

-- ============================================================
-- OPTIONS I WANT THAT BLOW DOES NOT HAVE
-- ============================================================
do
  -- Blow shows no line numbers at all -- his mode line's `L31` is the only line
  --  indicator on screen. `relativenumber` earns its place in Vim in a way it
  --  cannot in Emacs, because `10j` has no Emacs equivalent.
  vim.o.number = true
  vim.o.relativenumber = true

  vim.o.mouse = "a"
  vim.o.signcolumn = "yes" -- always on, so text never shifts when a diagnostic appears

  vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
  end)
end

-- ============================================================
-- KEYMAPS -- kickstart's names, so the muscle memory transfers
-- ============================================================
do
  local map = function(keys, rhs, desc)
    vim.keymap.set("n", keys, rhs, { desc = desc })
  end

  -- These keep kickstart's names so the muscle memory survives switching between
  --  configs, but each one is backed by a built-in rather than by Telescope. The
  --  ones with no plugin-free equivalent are listed at the bottom of this block.
  --
  --  Trailing space and no <CR>: the mapping leaves you on the command line with
  --  the command typed, so wildmenu's fuzzy matching does the picking.
  map("<leader>sf", ":find ", "[S]earch [F]iles")
  map("<leader>sg", ":grep ", "[S]earch by [G]rep")
  map("<leader>sh", ":help ", "[S]earch [H]elp")
  map("<leader>sk", ":map ", "[S]earch [K]eymaps")
  map("<leader>s.", ":browse oldfiles<CR>", '[S]earch Recent Files ("." for repeat)')
  map("<leader>sd", vim.diagnostic.setqflist, "[S]earch [D]iagnostics")
  map("<leader>sr", "<cmd>copen<CR>", "[S]earch [R]esume -- reopen the last result list")
  map("<leader>sc", "q:", "[S]earch [C]ommands -- the command-line window")
  map("<leader>sn", ":edit " .. vim.fn.stdpath("config") .. "/", "[S]earch [N]eovim files")
  map("<leader><leader>", ":buffer ", "[ ] Find existing buffers")

  -- `:vimgrep` over the current file only, which is the built-in shape of
  --  "fuzzy find in this buffer". The <Left>s park the cursor between the slashes.
  map("<leader>/", ":vimgrep //j %<Left><Left><Left><Left>", "[/] Search in current buffer")

  vim.keymap.set({ "n", "v" }, "<leader>sw", function()
    vim.cmd("grep -w " .. vim.fn.expand("<cword>"))
  end, { desc = "[S]earch current [W]ord" })

  --  Dropped, with no built-in worth faking: `<leader>ss` (Telescope's own picker
  --  list) and `<leader>s/` (live grep across open buffers).

  --  NOTE: no `]q` / `[q` here -- Neovim maps those to :cnext / :cprevious itself.
  map("<leader>q", vim.diagnostic.setloclist, "Open diagnostic [Q]uickfix list")

  -- Kickstart's arrow-key tip, verbatim apart from the loop. Failing silently
  --  would just be annoying; naming the replacement is what makes the habit stick.
  for arrow, key in pairs({ left = "h", down = "j", up = "k", right = "l" }) do
    vim.keymap.set(
      "n",
      "<" .. arrow .. ">",
      ('<cmd>echo "Use %s to move!!"<CR>'):format(key),
      { desc = "Use " .. key .. " to move" }
    )
  end
end

-- ============================================================
-- STATUSLINE -- core's, plus the LSP field
-- ============================================================
--  Reassigned in full rather than appended to. Keep in sync with `init.lua`.
vim.o.statusline = table.concat({
  " %t%m%r", -- basename, then [+] and [RO] when they apply
  "  %P", -- where the *window* sits in the file, not the cursor
  "  %l",
  [[%{empty(get(b:,'branch',''))?'':'  '.b:branch}]],
  "  %y",
  [[%{v:lua.LspStatus()}]], -- defined in the LSP section below
  [[%{&fileformat!='unix'?'  ['.&fileformat.']':''}]],
  [[%{&fileencoding!='' && &fileencoding!='utf-8' ? '  '.&fileencoding : ''}]],
  "%=", -- left-aligned; the rest of the bar stays empty
})

-- ============================================================
-- LSP -- built in, no nvim-lspconfig and no mason
-- ============================================================
do
  -- Each server is a file in `lsp/`, found by name on the runtimepath. A server
  --  whose binary is missing simply never attaches; that is not an error, and it
  --  is how `rust_analyzer` stays quiet until you are inside `rez env rust`.
  --  Kept in a variable rather than inlined, because `LspStatus()` below has to ask
  --  what filetypes each one claims and `vim.lsp.config` is not enumerable --
  --  `pairs()` on it yields only `_configs`.
  local servers = { "clangd", "basedpyright", "rust_analyzer" }
  vim.lsp.enable(servers)

  ---Statusline field. Empty when a server is attached, and empty when none is
  ---configured for this filetype. `[no lsp]` appears only when one *should* be here
  ---and is not: a crashed server, a missing binary, or nvim started outside the rez
  ---resolve that provides it.
  ---
  ---  This is the inverse of the usual `LSP +`, on the same reasoning as the `[dos]`
  ---  and encoding fields: a mark that is always present conveys nothing, and the
  ---  state worth knowing is when silence cannot be trusted. `LSP +` renders "no
  ---  server on a .txt file" and "the server for this .py file died on startup"
  ---  identically -- and the second is the one that costs you an afternoon of
  ---  wondering why nothing is underlined.
  ---
  ---  No caching: `get_clients()` measures ~0.3us, against a redraw budget of ~16ms.
  ---@return string
  function _G.LspStatus()
    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      return ""
    end
    for _, name in ipairs(servers) do
      local config = vim.lsp.config[name]
      if config and vim.tbl_contains(config.filetypes or {}, vim.bo.filetype) then
        return "  [no lsp]"
      end
    end
    return ""
  end

  -- Quiet by default. Blow runs no diagnostics at all; this keeps the information
  --  but off the canvas -- no virtual text competing with the code, underlines
  --  only for things that will actually fail, and the full message on demand.
  vim.diagnostic.config({
    virtual_text = false,
    underline = { severity = { min = vim.diagnostic.severity.WARN } },
    severity_sort = true,
    update_in_insert = false,
    float = { source = "if_many" }, -- the border comes from 'winborder'
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP keymaps",
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
      --  Deliberately short. `:help lsp-defaults`: Neovim creates `gra`, `gri`,
      --  `grn`, `grr`, `grt`, `grx` and `gO` as global keymaps at startup, and on
      --  attach it sets 'tagfunc' (so `<C-]>` is go-to-definition and `<C-t>` comes
      --  back), 'omnifunc' (`<C-x><C-o>`), 'formatexpr' (`gq` formats a motion) and
      --  `K` for hover. `<C-w>d` shows the diagnostic under the cursor. Mapping any
      --  of those again would only restate Neovim to itself.
      --
      --  These two have no default: declaration is a different thing from
      --  definition in a C/C++ header, and workspace symbols has no global binding.
      local map = function(keys, fn, desc)
        vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
      end
      map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
      map("gW", vim.lsp.buf.workspace_symbol, "Open Workspace Symbols")

      local client = vim.lsp.get_client_by_id(event.data.client_id)

      -- Built-in completion driven by the server: `<C-x><C-o>`, no plugin, no
      --  popup appearing as you type. `autotrigger` stays off deliberately.
      if client and client:supports_method("textDocument/completion") then
        vim.lsp.completion.enable(true, event.data.client_id, event.buf)
      end

      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        map("<leader>th", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }), { bufnr = event.buf })
        end, "[T]oggle Inlay [H]ints")
      end
    end,
  })
end

-- ============================================================
-- FORMATTING -- on demand only, never on save
-- ============================================================
do
  --  black costs ~0.2ms per line on an already-formatted file and ~0.85ms per line
  --  when it rewrites something, so a few thousand lines is seconds of work. None
  --  of that is startup and no configuration makes it faster, which is why nothing
  --  runs on save. Format when you mean to, and run `black .` before pushing.

  ---External formatters by filetype; anything not listed falls through to the
  ---language server. Each is given the buffer on stdin and returns the result on
  ---stdout, so the file on disk is never touched and the buffer is replaced in
  ---place. The filename is passed along only so the tool can find its own config
  ---(`pyproject.toml`, `stylua.toml`) and pick the right syntax.
  ---
  ---  Whichever binary your shell resolved is the one that runs -- start nvim from
  ---  `rez env python-3.10 black-25` and that is the black you get.
  local formatters = {
    python = function(name)
      return { "black", "--quiet", "--stdin-filename", name, "-" }
    end,
    lua = function(name)
      return { "stylua", "--stdin-filepath", name, "-" }
    end,
  }

  ---Filter the buffer through `argv`, keeping the cursor and scroll position.
  local function filter_through(buf, argv)
    if vim.fn.executable(argv[1]) ~= 1 then
      return vim.notify(argv[1] .. ": not on $PATH", vim.log.levels.WARN)
    end

    local input = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local result = vim.system(argv, { stdin = input }):wait()
    if result.code ~= 0 then
      return vim.notify(argv[1] .. ": " .. (result.stderr or "failed"), vim.log.levels.ERROR)
    end

    local formatted = vim.split(result.stdout or "", "\n")
    -- These tools always end with a newline, which `split` turns into a trailing
    --  empty element; writing it back would add a blank line on every format.
    if formatted[#formatted] == "" then
      table.remove(formatted)
    end
    if vim.deep_equal(input, formatted) then
      return
    end

    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)
    vim.fn.winrestview(view)
  end

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    local buf = vim.api.nvim_get_current_buf()
    local build = formatters[vim.bo[buf].filetype]
    if build then
      return filter_through(buf, build(vim.api.nvim_buf_get_name(buf)))
    end

    -- clangd embeds clang-format, rust-analyzer shells out to rustfmt. Check for a
    --  server that can actually format first: `vim.lsp.buf.format()` on a buffer
    --  with none reports "no matching language servers", which reads like a bug in
    --  the LSP setup rather than "nothing here formats this filetype".
    if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/formatting" }) == 0 then
      return vim.notify(("no formatter for filetype '%s'"):format(vim.bo[buf].filetype), vim.log.levels.WARN)
    end
    vim.lsp.buf.format({ bufnr = buf, timeout_ms = 5000 })
  end, { desc = "[F]ormat buffer" })
end

-- ============================================================
-- SMALL THINGS
-- ============================================================
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Flash the yanked text",
  group = vim.api.nvim_create_augroup("yank-highlight", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- -- ============================================================
-- -- RULERS
-- -- ============================================================
-- do
--   -- A ruler at each language's formatter width, so a line crossing it is one the
--   --  formatter is about to rewrite. Python gets a second, softer one.
--   --
--   --  NOTE: `colorcolumn` is window-local, not buffer-local, and this autocmd has no
--   --  `pattern` on purpose -- it assigns '' for filetypes with no entry, or the
--   --  ruler from the previous buffer lingers in the same window after `:e`.
--   local widths = {
--     python = "88,110", -- black default line length, FIXME: remove 110
--     lua = "120", -- stylua.toml column_width
--     rust = "100", -- rustfmt default max_width
--     c = "80", -- clang-format LLVM ColumnLimit
--     cpp = "80",
--   }
--
--   vim.api.nvim_create_autocmd("FileType", {
--     desc = "Set colorcolumn per filetype",
--     group = vim.api.nvim_create_augroup("colorcolumn", { clear = true }),
--     callback = function(args)
--       vim.wo.colorcolumn = widths[args.match] or ""
--     end,
--   })
-- end

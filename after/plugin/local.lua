--  Everything here layers over `init.lua` rather than restating it. The statusline
--  used to be the one exception -- copied wholesale to add a field, and kept in
--  sync by hand -- until init.lua grew a reserved `StatuslineExtra` slot. Filling
--  it is now the LSP section's job, and nothing here reassigns 'statusline'.

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
-- PLUGINS -- local only; master stays plugin-free
-- ============================================================
do
  vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pairs", version = "stable" },
    { src = "https://github.com/nvim-mini/mini.surround", version = "stable" },
  })

  require("mini.pairs").setup()
  require("mini.surround").setup()

  -- Shipped inside Neovim since 0.12, but not loaded unless asked for. `undofile`
  --  is on in init.lua, so the tree already survives across sessions -- this is
  --  the only thing that lets you see it. `:Undotree`, cursor moves the undo.
  vim.cmd.packadd("nvim.undotree")

  -- `:Cfilter foo` keeps only the quickfix entries matching foo, `:Cfilter! foo`
  --  drops them, and they compose -- so a 400-hit :grep narrows to the dozen you
  --  meant in two keystrokes each. This is the verb the grep -> quickfix -> ]q loop
  --  in init.lua was missing: it could produce a list and walk it, but not thin it.
  --  Bundled with Neovim; `:Lfilter` does the same for a location list.
  vim.cmd.packadd("cfilter")

  -- 0.13 grows a `:packupdate` command; on 0.12 the update path is a Lua call,
  --  which is not something anyone types from memory. Nothing is installed
  --  outright: the call opens a confirmation buffer holding the changelog, and
  --  the update happens when you :write it.
  vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
  end, { desc = "Update the plugins managed by vim.pack" })
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

  -- The completion popup is as wide as its widest entry, and rust-analyzer and
  --  basedpyright both return signatures that run the full width of the window.
  --  Capped, it sits beside the code instead of on top of it.
  vim.o.pummaxwidth = 60
  vim.o.pumheight = 12 -- was 0, meaning "as tall as the window"; same reasoning

  -- Per-project `.nvim.lua`, for what cannot be global: a 'makeprg' this repo
  --  alone needs, an extra root marker, a formatter everyone here disagrees
  --  about. Neovim asks before sourcing one and remembers the answer, so a repo
  --  you cloned cannot quietly run code -- though it can ask, and a prompt is an
  --  easy thing to wave through. `:trust` manages the list.
  vim.o.exrc = true

  vim.o.list = true
  vim.opt.listchars = { tab = "\u{bb} ", trail = "\u{b7}", nbsp = "\u{2423}" }

  vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
  end)
end

-- ============================================================
-- FILETYPES NEOVIM DOES NOT KNOW
-- ============================================================
do
  -- Neovim ships no ftdetect, ftplugin, indent or syntax file for Jai, so a `.jai`
  --  buffer has filetype `""` -- and an empty filetype is not merely cosmetic. It
  --  means 'commentstring' is empty too, so `gcc` silently does nothing; it means
  --  no FileType autocmd can ever fire for the buffer, whatever its pattern; and
  --  it means indentation falls through to Vim's raw defaults.
  --
  --  Registering the extension is the whole fix. `vim.filetype.add` is the Lua
  --  spelling of an ftdetect file, and once the name exists, `after/ftplugin/jai.lua`
  --  is found by the normal runtimepath search -- which is where the style itself
  --  lives, buffer-locally, rather than as a global in `init.lua`.
  vim.filetype.add({ extension = { jai = "jai" } })
end

-- ============================================================
-- KEYMAPS -- only what Neovim has no key for already
-- ============================================================
do
  -- What used to be here was kickstart's `<leader>s*` family. Every one of them
  --  was a three-key alias for a command that is already short, so the whole set
  --  is gone and the commands are the interface:
  --
  --    <leader>sf  ->  :find <name>          <leader>sr  ->  :cope
  --    <leader>sg  ->  :grep <pattern>       <leader>sn  ->  :e $MYVIMRC
  --    <leader>sh  ->  :h <subject>          <leader>s.  ->  :bro old
  --    <leader>sk  ->  :map                  <leader>sc  ->  q:   (native, shorter)
  --    <leader>/   ->  :vim //j %            <leader><leader>  ->  :b <name>
  --
  --  `<leader>sw` was "grep the word under the cursor", which Vim already spells:
  --
  --    :gr -w <C-r><C-w>
  --
  --  |c_CTRL-R_CTRL-W| puts the word under the cursor onto the command line, and
  --  works in front of *any* command -- :h, :b, :e -- which one mapping per verb
  --  never could. That is the trade: a mapping saves typing a colon, a command
  --  composes.
  --
  --  Wildmenu's 'fuzzy' matching does the picking either way; none of that came
  --  from the mappings. `<leader>sd` and `<leader>q` became `:Diagnostics`, in the
  --  LSP section -- the one thing here with no native command behind it.
  --
  --  NOTE: `]q` / `[q` were never mapped -- Neovim maps those itself, along with
  --  `]d`, `]l`, `]b`, `]a`, `]t` and `]<Space>`. See |]q| and friends.

  -- Manual completion only: no popup unless you ask for it. After text, <Tab>
  --  starts or advances built-in insert completion; after whitespace, it remains
  --  indentation.
  --  Three legs, in this order. Neovim maps <Tab> itself -- to `vim.snippet.jump`
  --  -- and overriding it without the snippet leg is a silent regression: a
  --  completion from clangd or rust-analyzer expands with placeholders, and <Tab>
  --  then does nothing useful, stranding you on the first one. The popup wins when
  --  it is open, because cycling is what you meant; the snippet wins next.
  vim.keymap.set("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then
      return "<C-n>"
    end

    if vim.snippet.active({ direction = 1 }) then
      return "<Cmd>lua vim.snippet.jump(1)<CR>"
    end

    local col = vim.fn.col(".") - 1
    if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
      return "<Tab>"
    end

    return "<C-n>"
  end, { expr = true, desc = "Complete word" })

  vim.keymap.set("i", "<S-Tab>", function()
    if vim.fn.pumvisible() == 1 then
      return "<C-p>"
    end

    if vim.snippet.active({ direction = -1 }) then
      return "<Cmd>lua vim.snippet.jump(-1)<CR>"
    end

    return "<S-Tab>"
  end, { expr = true, desc = "Previous completion" })
end

-- ============================================================
-- LSP -- built in, no nvim-lspconfig and no mason
-- ============================================================
do
  -- Each server is a file in `lsp/`, found by name on the runtimepath. A server
  --  whose binary is missing simply never attaches; that is not an error, and it
  --  is how `rust_analyzer` stays quiet until you are inside `rez env rust`.
  --  Kept in a variable rather than inlined, because `StatuslineExtra()` below has to ask
  --  what filetypes each one claims and `vim.lsp.config` is not enumerable --
  --  `pairs()` on it yields only `_configs`.
  local servers = { "clangd", "basedpyright", "rust_analyzer", "ols" }
  vim.lsp.enable(servers)

  ---Fills the `StatuslineExtra` slot `init.lua` reserves, which is why the bar is
  ---not reassigned anywhere in this file. Empty when a server is attached, and
  ---empty when none is configured for this filetype. `[no lsp]` appears only when
  ---one *should* be here and is not: a crashed server, a missing binary, or nvim
  ---started outside the rez resolve that provides it.
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
  function _G.StatuslineExtra()
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

  -- `virtual_text` is off above, and `<C-w>d` floats the one under the cursor,
  --  which answers "what is wrong here". `virtual_lines` answers the other
  --  question -- "all of them, in full, now" -- rendered inline beneath each
  --  line. Much too loud to leave on, and exactly right for the minute spent
  --  reading a rust-analyzer trait error. Same shape as `<leader>th` below.
  -- The one thing in the old keymap block with no native command behind it:
  --  `vim.diagnostic.setqflist()` exists, `:Diagnostics` did not. A bang sends the
  --  buffer's diagnostics to the location list instead of the quickfix list, which
  --  is the same distinction :grep and :lgrep draw.
  vim.api.nvim_create_user_command("Diagnostics", function(opts)
    if opts.bang then
      vim.diagnostic.setloclist()
    else
      vim.diagnostic.setqflist()
    end
  end, { bang = true, desc = "Diagnostics into the quickfix list (! for location list)" })

  vim.keymap.set("n", "<leader>tl", function()
    vim.diagnostic.config({ virtual_lines = not vim.diagnostic.config().virtual_lines })
  end, { desc = "[T]oggle diagnostic [L]ines" })

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
-- BUILDING AND RUNNING -- separate verbs, because they answer differently
-- ============================================================
do
  -- init.lua wires :grep -> quickfix -> ]q and calls the result "a list you
  --  walk". Compile errors are the other half of that loop and they arrive by the
  --  same route: :make runs 'makeprg', 'errorformat' parses what comes back, and
  --  the result is the list you already know how to step through.
  --
  --  Building and running are two keys, not one. `:make` is silent and speaks
  --  through the quickfix list, which is exactly right for a compiler: no output
  --  means it worked. Running a program is the reverse -- the output *is* the
  --  result -- so `<leader>r` opens a terminal split and shows it. Conflating the
  --  two means a script that succeeds looks identical to a keymap that did
  --  nothing, which is precisely what happened when <leader>b ran Python.
  --
  --  Neovim ships compiler plugins for part of this. `:compiler gcc` and
  --  `:compiler cargo` set an 'errorformat' that is already debugged, which is
  --  not a pattern to hand-write when someone has done it for you. Odin and
  --  Python have none, so those two are spelled out. Without a bang `:compiler`
  --  sets its options buffer-locally, which is what makes this safe from a
  --  FileType autocmd.
  local compilers = { c = "gcc", cpp = "gcc", rust = "cargo" }

  -- Read by cargo.vim as it loads, producing `cargo build $*`. Without it
  --  'makeprg' is a bare `cargo` and :make just prints the help text.
  vim.g.cargo_makeprg_params = "build"

  -- `main.odin(12:5) Error: undeclared identifier: foo`
  local odin_errorformat = [[%f(%l:%c) %m]]

  -- A Python traceback is one error smeared over many lines. Each `File "...",
  --  line N` frame opens an entry (%A), the indented source line below it is a
  --  continuation (%C), and the unindented `ValueError: boom` that ends the
  --  traceback (%Z) attaches to the last frame opened -- the innermost one, which
  --  is where the cursor should land. %-G discards the rest: the "Traceback"
  --  banner, and the caret line under a SyntaxError.
  local python_errorformat = table.concat({
    [[%A%*\sFile "%f"\, line %l\, in %o]],
    [[%A%*\sFile "%f"\, line %l]],
    [[%C %.%#]],
    [[%Z%m]],
    [[%-G%.%#]],
  }, ",")

  -- Same shape as `formatters` in the FORMATTING section above: filetype to a
  --  function of the buffer's name -- plus the argument string -- returning the
  --  command line to run.
  --
  --  Each one places the arguments itself, because appending them is wrong in
  --  three of the four cases. `cargo run foo` passes `foo` to *cargo*, which is why
  --  it needs `--` first; odin is the same. `make run foo` reads `foo` as a second
  --  target, so the args go in a variable and the Makefile has to pick them up with
  --  `$(ARGS)` -- a convention, not a guarantee. Only Python takes them plainly.
  --
  --  `args` is passed through unescaped: it is a fragment of a shell command line,
  --  so quoting, globs and `>` redirects work the way they would in the shell. The
  --  *filename* is escaped, because that one is not yours to quote.
  local runners = {
    c = function(_, args)
      return "make run" .. (args == "" and "" or " ARGS=" .. vim.fn.shellescape(args))
    end,
    cpp = function(_, args)
      return "make run" .. (args == "" and "" or " ARGS=" .. vim.fn.shellescape(args))
    end,
    rust = function(_, args)
      return "cargo run" .. (args == "" and "" or " -- " .. args)
    end,
    odin = function(_, args)
      return "odin run ." .. (args == "" and "" or " -- " .. args)
    end,
    python = function(name, args)
      return "python " .. vim.fn.shellescape(name) .. (args == "" and "" or " " .. args)
    end,
  }

  vim.api.nvim_create_autocmd("FileType", {
    desc = "Set 'makeprg' and 'errorformat' for :make",
    group = vim.api.nvim_create_augroup("make", { clear = true }),
    pattern = { "c", "cpp", "rust", "odin", "python" },
    callback = function(event)
      local ft = vim.bo[event.buf].filetype
      if compilers[ft] then
        vim.cmd.compiler(compilers[ft])
      elseif ft == "odin" then
        vim.bo[event.buf].makeprg = "odin build ."
        vim.bo[event.buf].errorformat = odin_errorformat
      elseif ft == "python" then
        vim.bo[event.buf].makeprg = "python %"
        vim.bo[event.buf].errorformat = python_errorformat
      end
    end,
  })

  -- `:update` first -- compiling the file on disk while the buffer says something
  --  else is how you spend ten minutes on an error that is no longer there. It
  --  writes only a modified buffer, so it costs nothing the rest of the time.
  --
  --  `silent` keeps the compiler's own chatter off the screen: the quickfix list
  --  is the output. What that costs is any sign of progress during a long build.
  --
  --  Python is deliberately absent: it has no build step, and `python %` would
  --  *run* the file. Its 'makeprg' is still set above, so a bare `:make` remains
  --  available for the odd time you want a traceback parsed into the quickfix
  --  list -- but the build key says so rather than silently running your program.
  local buildable = { c = true, cpp = true, rust = true, odin = true }

  vim.keymap.set("n", "<leader>b", function()
    local ft = vim.bo.filetype
    if not buildable[ft] then
      local hint = runners[ft] and " -- use <leader>r to run it" or ""
      return vim.notify(("nothing to build for filetype '%s'%s"):format(ft, hint), vim.log.levels.WARN)
    end
    vim.cmd("update")
    vim.cmd("silent make")
    vim.cmd("redraw!")
  end, { desc = "[B]uild" })

  -- The run side. A terminal split rather than `:!`: the program keeps the screen
  --  until you are done reading it, scrollback works, and `<C-\><C-n>` gets you
  --  back to normal mode. 'splitbelow' is on, so `:new` opens underneath.
  --
  --  `make run` for C and C++ because the binary's name is a property of the
  --  Makefile, not something Neovim can guess. Projects that spell it differently
  --  are what 'exrc' and a `.nvim.lua` are for.
  local function run(args)
    local build = runners[vim.bo.filetype]
    if not build then
      return vim.notify(("nothing to run for filetype '%s'"):format(vim.bo.filetype), vim.log.levels.WARN)
    end
    vim.cmd("update")
    local cmd = build(vim.api.nvim_buf_get_name(0), args or "")
    vim.cmd.new()
    vim.cmd("resize 15")
    -- `termopen()` is deprecated as of 0.12; this is its replacement.
    vim.fn.jobstart(cmd, { term = true })
  end

  -- `:Run --flag file.txt` passes arguments; `:Run` alone is the bare run. The
  --  command exists so the arguments have somewhere to live: command-line history
  --  then remembers them, so `:Run<Up>` repeats the last invocation and `q:` edits
  --  it -- which is the built-in answer to "remember my arguments", and better than
  --  a variable this file would have to manage.
  vim.api.nvim_create_user_command("Run", function(opts)
    run(opts.args)
  end, { nargs = "*", complete = "file", desc = "Run the current file, with arguments" })

  -- Two keys: the lowercase one acts, the uppercase one leaves you on the command
  --  line with `:Run ` typed, so wildmenu completes filenames as you go. No <CR> on
  --  the second, deliberately.
  vim.keymap.set("n", "<leader>r", function()
    run("")
  end, { desc = "[R]un" })
  vim.keymap.set("n", "<leader>R", ":Run ", { desc = "[R]un with arguments" })

  -- init.lua already opens the quickfix window after :grep, under its own augroup
  --  and its own pattern list. A second autocmd rather than an edit to that one:
  --  reusing the name with `clear = true` would delete init.lua's copy, and this
  --  file is meant to read as a diff against that one, not to reach into it.
  vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    desc = "Open quickfix when :make has entries",
    group = vim.api.nvim_create_augroup("quickfix-make", { clear = true }),
    pattern = "make",
    callback = function()
      vim.cmd(#vim.fn.getqflist() > 0 and "copen" or "cclose")
    end,
  })
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

-- 'autoread' is on by default, but it only reloads a file once Neovim notices the
--  timestamp moved, and it does not go looking on its own. Fine until the
--  `black .` before a push -- or a branch switch -- rewrites a file that is open
--  here, at which point the buffer is quietly stale and the next :write is the
--  one that has to ask whether you meant it. 0.13 grows filesystem watchers for
--  this; on 0.12 you ask.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  desc = "Check for files changed outside Neovim",
  group = vim.api.nvim_create_augroup("checktime", { clear = true }),
  callback = function()
    if vim.o.buftype == "" then
      vim.cmd.checktime()
    end
  end,
})

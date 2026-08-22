-- rust-analyzer. Only on $PATH inside `rez env rust`; outside one it never
--  attaches, which is the intended behaviour.
--
--  rust-analyzer needs the standard library *source* (the `rust-src` component) to
--  resolve `std`/`core` and infer types. The rez rust packages ship rustc, cargo,
--  rustfmt and rust-analyzer but not rust-src, so it logs
--    "can't load standard library, try installing `rust-src`"
--  and every type resolves to unknown -- which silently kills inlay hints and most
--  code actions while leaving the server otherwise attached and apparently fine.
--
--  rust-src is unpacked under ~/.local/share/rust-src/<version>, with `current`
--  symlinked to the version matching the rez rust package. To update it:
--    V=<rustc version>
--    curl -sSLO https://static.rust-lang.org/dist/rust-src-$V.tar.xz
--    tar -xf rust-src-$V.tar.xz
--    mkdir -p ~/.local/share/rust-src/$V
--    cp -r rust-src-$V/rust-src/lib ~/.local/share/rust-src/$V/
--    ln -sfn $V ~/.local/share/rust-src/current
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = { "Cargo.toml", "rust-project.json", ".git" },

  -- NOTE: `init_options`, not `settings`. rust-analyzer's own schema says of
  --  `cargo.sysrootSrc`: "This option does not take effect until rust-analyzer is
  --  restarted" -- it is read once, during `initialize`, before the workspace is
  --  loaded. Neovim delivers `settings` only *after* that, by answering
  --  `workspace/configuration` and pushing `didChangeConfiguration`, so a sysroot
  --  set there arrives too late and you get
  --    "can't load standard library from sysroot ... try installing `rust-src`"
  --  even though the path is correct. Verified against a mock server: with
  --  `settings` alone the initialize request carries no `initializationOptions`
  --  at all.
  --
  --  The shape differs too: `initializationOptions` takes the config nested
  --  *without* the `rust-analyzer.` prefix that `settings` needs.
  init_options = {
    cargo = {
      sysrootSrc = vim.fn.expand("~/.local/share/rust-src/current/lib/rustlib/src/rust/library"),
    },
  },
}


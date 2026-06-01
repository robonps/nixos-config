return {
  {
    "Saghen/blink.cmp",
    lazy = false, 
    version = "1.*",
    dependencies = { 'rafamadriz/friendly-snippets' },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      keymap = {
        preset = "default",f
      },

      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  }
}
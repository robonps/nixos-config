return {
  {
    "neovim/nvim-lspconfig", version = "*",
    config = function()
      -- The new native 0.11/0.12+ way to start language servers
      -- No require('lspconfig') needed!
      vim.lsp.config("pyright", {})
      vim.lsp.config("nil_ls", {})
      vim.lsp.config("lua_ls", {})
      vim.lsp.config("bashls", {})

      -- Start them automatically when opening a matching file type
      vim.lsp.enable("pyright")
      vim.lsp.enable("nil_ls")
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("bashls")

      -- Your identical global LSP keymaps
      vim.keymap.set('n', '<leader>k', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show Diagnostics' })
    end
  }
}

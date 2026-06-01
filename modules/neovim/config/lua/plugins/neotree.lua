return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
    },
    lazy = false, -- neo-tree will lazily load itself
    keys = {
        { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
        { "<leader>fe", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
    },
    opts = {
        enable_git_status = true,
    }
  }
}

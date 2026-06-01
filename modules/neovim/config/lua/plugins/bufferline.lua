return {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    lazy = false,
    keys = {
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },

        --- Leader + c to close current tab
        { "<leader>c", "<cmd>bdelete<cr>", desc = "Close Buffer" },
    },
    opts = {
        options = {
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "File Explorer",
                    text_align = "center",
                    separator = true
                }
            },
        },
    },
}


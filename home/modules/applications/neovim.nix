{ pkgs, nvf, ... }: {
    programs.nvf = {
        enable = true;

        settings.vim = {
            viAlias = true;
            vimAlias = true;


            theme = {
                enable = true;
                name = "gruvbox";
                style = "dark";
            };

            languages = {
                enableLSP = true;
                enableTreesitter = true;

                nix.enable = true;
                python.enable = true;
            };

            options.tabstop = 4;
            options.shiftwidth = 4;

            statusline.lualine.enable = true;
            filetree.neo-tree.enable = true;
            telescope.enable = true;
            autocomplete.nvim-cmp.enable = true;
            tabline.nvimBufferline.enable = true;
        };
    };
}

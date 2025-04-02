{ pkgs, nvf, ... }: let

    nvfTheme = "gruvbox"; # Set the default theme for Neovim

in {
    programs.nvf = {
        enable = true; # Enable Neovim configuration

        settings.vim = {
            viAlias = true; # Enable `vi` alias
            vimAlias = true; # Enable `vim` alias

            theme = {
                enable = true; # Enable theming
                name = nvfTheme; # Set theme name
                style = "dark"; # Use dark mode
            };

            languages = {
                enableLSP = true; # Enable Language Server Protocol
                enableTreesitter = true; # Enable Treesitter for syntax highlighting

                nix.enable = true; # Enable Nix support
                python.enable = true; # Enable Python support
                go.enable = true; # Enable Go support
            };

            # Configure indentation
            options.tabstop = 4;
            options.shiftwidth = 4;

            # Enable various plugins and features
            statusline.lualine.enable = true;
            filetree.neo-tree.enable = true;
            telescope.enable = true;
            autocomplete.nvim-cmp.enable = true;
            tabline.nvimBufferline.enable = true;
        };
    };
}

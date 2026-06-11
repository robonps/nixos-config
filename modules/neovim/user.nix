{ config, pkgs, ... }:
{

  home.packages = with pkgs; [

    neovim

    ripgrep
    fd
    imagemagick
    gnumake

    nerd-fonts.symbols-only

    tree-sitter
    gcc

    git
    curl
    gzip
    unzip

    # LSP Servers
    pyright # Python LSP
    nil # Nix LSP
    lua-language-server # Lua LSP
    bash-language-server # Bash LSP
    dockerfile-language-server # Dockerfile LSP

    # Formatters & Linters
    nixfmt # Nix Formatter
    stylua # Lua Formatter
    shellcheck # Shell Linter
    hadolint # Dockerfile Linter
  ];

  programs.neovim = {
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;
  };

  xdg.configFile."nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/robert/nixos-config/modules/neovim/config";
    #recursive = true;
  };
}


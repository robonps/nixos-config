{ ... }: {
    imports = [
        # Git configuration
        ./git.nix
        # Syncthing service configuration
        ./syncthing.nix
        # VSCode configuration
        ./vscode.nix
        # Neovim configuration
        ./neovim.nix
    ];
}

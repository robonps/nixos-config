{ pkgs, ... }: {
    imports = [
        ./git.nix
        ./syncthing.nix
        ./vscode.nix
        ./neovim.nix
    ];
}
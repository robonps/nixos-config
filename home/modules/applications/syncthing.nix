{ pkgs, ... }: {
    services.syncthing = {
        enable = true; # Enable the Syncthing service
    };
}
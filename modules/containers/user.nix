{ pkgs, ... }: {
  home.packages = with pkgs; [
    podman-compose
    podman-tui
  ];

  services.podman = {
    enable = true;
  };
}
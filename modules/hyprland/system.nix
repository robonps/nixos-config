{pkgs, ...}: {
  programs.hyprland.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # FILE MANAGER STUFF

  # Required for file manager to see USB sticks
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.gnome.gnome-keyring.enable = true;
  environment.pathsToLink = [ "/share/thumbnailers" ];

  # GStreamer for file info
  nixpkgs.overlays = [
    (final: prev: {
      nautilus = prev.nautilus.overrideAttrs (nprev: {
        buildInputs =
          nprev.buildInputs
          ++ (with pkgs.gst_all_1; [
            gst-plugins-good
            gst-plugins-bad
          ]);
      });
    })
  ];

  # Dconf (for theming)
  programs.dconf.enable = true;

  # Quick Preview
  # Allows you to hit "Space" to preview files like on macOS
  services.gnome.sushi.enable = true;

  # File indexers
  services.gnome.tinysparql.enable = true;
  services.gnome.localsearch.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus # File manager

    hyprpolkitagent # Authentication Agent

    libheif # HEIC Preview
    libheif.out # HEIC Preview

    font-awesome # Font Icons

    ffmpegthumbnailer # Video Thumbnails
  ];
}

{pkgs, ...}: {
  # Install the Pywalfox binary
  home.packages = [pkgs.pywalfox-native];

  # 2. Link the Connector so Librewolf can find it
  # (Firefox/Librewolf looks in ~/.librewolf/native-messaging-hosts/ by default)
  home.file.".librewolf/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
    name = "pywalfox";
    description = "Pywalfox";
    path = "${pkgs.pywalfox-native}/bin/pywalfox";
    type = "stdio";
    allowed_extensions = ["pywalfox@frewacom.org"];
  };

  # Theming for librewolf
  programs.librewolf = {
    policies = {
      ExtensionSettings = {
        # The ID for Pywalfox
        "pywalfox@frewacom.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}

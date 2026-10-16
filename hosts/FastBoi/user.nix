{pkgs, lib, ...}: let
  # Use the existing SDK server rather than detecting/initialising hardware a
  # second time with the GUI's separate ASRock channel-swap settings.
  openrgb-client = pkgs.writeShellScriptBin "openrgb" ''
    if [ "$#" -eq 0 ]; then
      set -- --gui
    fi
    exec ${pkgs.openrgb}/bin/openrgb --client 127.0.0.1:6742 --nodetect "$@"
  '';
  toggle-birghtness = pkgs.writeShellScriptBin "toggle-brightness" (builtins.readFile ./toggle-brightness.sh);
  toggle-microphone = pkgs.writeShellApplication {
    name = "toggle-microphone";
    runtimeInputs = [pkgs.wireplumber pkgs.libnotify];
    text = ''
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      state=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
      if [[ "$state" == *"[MUTED]"* ]]; then
        message="Microphone muted"
        icon="microphone-sensitivity-muted-symbolic"
      else
        message="Microphone unmuted"
        icon="audio-input-microphone-symbolic"
      fi
      notify-send --app-name="Microphone" --icon="$icon" --expire-time=2000 \
        --hint=string:x-canonical-private-synchronous:microphone-mute \
        --hint=boolean:transient:true "$message"
    '';
  };
in {
  imports = [
    ../../common/user.nix
    ../../modules/hyprland/user.nix
    ../../modules/gaming/user.nix
    ../../modules/DAW/user.nix     # Bitwig Studio and Decent Sampler for music production
    ../../modules/ai/user.nix      # AI tools
    ../../modules/codex/user.nix   # Codex and executable reverse engineering
  ];

  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  home.packages = [
    openrgb-client
    toggle-birghtness
    toggle-microphone
  ];

  # Follow Matugen's primary colour with a dim, static motherboard tint.
  xdg.configFile."openrgb/matugen.json".text = builtins.toJSON {
    device = "ASRock B850M-X WiFi R2.0";
    channel_order = "GRB"; # Matches the server's pinned ASRock RGSwap settings.
    intensity = 18; # Percentage of each RGB channel, independent of mode brightness.
    saturation = 120; # 100 preserves the palette; 120 adds a little more colour.
    transition_ms = 800; # Fade duration; 0 applies the colour immediately.
  };

  xdg.desktopEntries."org.openrgb.OpenRGB" = {
    name = "OpenRGB";
    genericName = "RGB lighting control";
    exec = "${openrgb-client}/bin/openrgb --gui";
    icon = "OpenRGB";
    terminal = false;
    categories = [ "Utility" ];
  };

  xdg.configFile."waybar/config.jsonc".source = lib.mkForce (
    pkgs.writeText "fastboi-waybar-config.jsonc" (
      lib.replaceStrings [ ''"pulseaudio",'' ] [ "" ]
        (builtins.readFile ../../modules/hyprland/modules/waybar/config.jsonc)
    )
  );

  # Apply these overrides after the shared bindings generated from settings.
  wayland.windowManager.hyprland.extraConfig = ''
    unbind = , XF86AudioMute
    unbind = , XF86AudioRaiseVolume
    unbind = , XF86AudioLowerVolume
    bindl = , XF86AudioMute, exec, ${toggle-microphone}/bin/toggle-microphone
  '';

  wayland.windowManager.hyprland.settings = {
    exec-once = [ "openrgb-tint" ];
    bind = [
      "$mainMod SHIFT, Q, exec, toggle-brightness"
    ];
    # Syntax: "NAME, RESOLUTION, POSITION, SCALE"
    monitor = [
      #"desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, 1920x1080@60, 0x130, 1"
      "desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027, 2560x1440@255, 1920x0, 1, bitdepth, 10"
      #"desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, 1920x1080@60, 4480x130, 1"
    ];

    render = {
      cm_auto_hdr = 1;
    };

    cursor = {
      no_break_fs_vrr = 1;
    };

#    # Bind workspaces 1-3 to specific screens so they don't jump around
#    workspace = [
#      # Workspace 1 -> Left Monitor
#      "1, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, default:true"
#      
#      # Workspace 2 -> Middle Monitor
#      "2, monitor:desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027, default:true"
#      
#      # Workspace 3 -> Right Monitor
#      "3, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, default:true"
#    ];

    misc = {
      vrr = 2; 
    };
  };
}

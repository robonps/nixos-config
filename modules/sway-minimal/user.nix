{ pkgs, config, lib, ... }: 

let
  swaySmartKill = pkgs.writeShellScriptBin "sway-smart-kill" ''
    # Find the app_id of the currently focused window
    APP_ID=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | objects | select(.focused==true) | .app_id // empty')
    
    # If the focused window is NOT our background terminal, kill it
    if [ "$APP_ID" != "foot-bg" ]; then
      ${pkgs.sway}/bin/swaymsg kill
    fi
  '';

  # 2. Script to enforce strict floating/tiling rules
  swaySmartFloat = pkgs.writeShellScriptBin "sway-smart-float" ''
    APP_ID=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | objects | select(.focused==true) | .app_id // empty')
    WS_NAME=$(${pkgs.sway}/bin/swaymsg -t get_workspaces | ${pkgs.jq}/bin/jq -r '.[] | select(.focused==true) | .name // empty')
    
    # Rule A: Never allow the background terminal to float
    if [ "$APP_ID" == "foot-bg" ]; then
      exit 0
    fi
    
    # Rule B: Never allow any window on Workspace 1 to tile (everything stays floating)
    if [ "$WS_NAME" == "1" ]; then
      exit 0
    fi
    
    # If we are on Workspaces 2-9, toggle floating normally
    ${pkgs.sway}/bin/swaymsg floating toggle
  '';


  # 3. Script to prevent moving the background terminal to other workspaces
  swaySmartMove = pkgs.writeShellScriptBin "sway-smart-move" ''
    # Find the app_id of the currently focused window
    APP_ID=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | objects | select(.focused==true) | .app_id // empty')
    
    # If it is the background terminal, refuse to move it
    if [ "$APP_ID" == "foot-bg" ]; then
      exit 0
    fi
    
    # Otherwise, move the window to the workspace number passed to the script
    ${pkgs.sway}/bin/swaymsg move container to workspace number $1
  '';

  cliphistPreview = pkgs.writeShellScriptBin "cliphist-preview" ''
    # If the fzf line contains "[[ binary data", it's an image
    if [[ "$1" == *"[[ binary data"* ]]; then
      # Decode the image and render it as Sixel graphics
      echo "$1" | cliphist decode | chafa -f sixel -s 40x20 -
    else
      # It's just text, so decode and print it normally
      echo "$1" | cliphist decode
    fi
  '';

  cliphistMenu = pkgs.writeShellScriptBin "cliphist-menu" ''
    # 1. Capture the selection. If you press Escape, this variable stays empty.
    # Added --bind to execute 'cliphist delete' on the highlighted item when pressing the Delete key, then instantly reload the list
    selected=$(cliphist list | fzf --no-sort --reverse --prompt='Clipboard> ' --preview='cliphist-preview {}' --preview-window=right:50% --bind 'delete:execute(echo {} | cliphist delete)+reload(cliphist list)')

    # 2. If empty (Escape), exit instantly. This stops the "extracting id" error.
    if [ -z "$selected" ]; then
      exit 0
    fi

    echo "$selected" | cliphist decode | wl-copy 2>/dev/null
  '';

  cliphistTextWatcher = pkgs.writeShellScriptBin "cliphist-text-watcher" ''
    # Read the incoming clipboard text
    content=$(cat)
    
    # If the text starts with the browser's image meta tag, throw it away silently.
    if [[ "$content" == "<meta http-equiv="* ]]; then
      exit 0
    fi
    
    # Otherwise, store it normally
    printf "%s" "$content" | cliphist store --max-items 200
  '';

in {

  imports = [
    ./modules
    ../tmux/user.nix
  ];

  options.font = lib.mkOption {
    type = lib.types.str;
    default = "CozetteVector";
    description = "The font to use for the terminal and lock screen.";
  };


config = {
  home.packages = with pkgs; [
      wl-clipboard
      wl-clip-persist
      cliphist
      fzf
      jq
      autotiling-rs
      swayidle
      brightnessctl
      chafa
      nerd-fonts.symbols-only
      swaySmartKill  # Custom kill script
      swaySmartFloat # Custom float script
      swaySmartMove  # Custom move script
      cliphistPreview # Custom clipboard preview script
      cliphistMenu    # Custom clipboard menu script
      cliphistTextWatcher # Custom clipboard text watcher
    ];

    programs.foot = {
      enable = true;
      server.enable = false;
      settings = {
        main = {
          font = "${config.font}:size=15,SymbolsNerdFont:size=15";
        };
        colors-dark = {
          background = "000000"; # Pure hardware midnight black
          foreground = "c5c8c6";
        };
      };
    };

  wayland.windowManager.sway = {
    enable = true;
    config = null;

    extraConfig = ''
      set $mod Mod4
      set $term foot

      font pango:${config.font} 13

      # --- AUTOSTART ---
      # Launch the special background terminal
      exec $term --app-id="foot-bg" -e tmux new-session -A -s main

      exec autotiling-rs

      exec wl-clip-persist --clipboard both

      exec wl-paste --type text --watch cliphist-text-watcher
      exec wl-paste --type image --watch cliphist store --max-items 200

      

      # --- WORKSPACE 1 STRICT RULES ---
      assign [app_id="foot-bg"] workspace number 1
      for_window [workspace="1"] floating enable
      for_window [app_id="foot-bg"] floating disable, border none


      # --- SPECIAL RULES ---
      for_window [app_id="cliphist-menu"] floating enable, resize set 800 600, move position center, focus

      # --- APPEARANCE ---
      default_border pixel 2
      default_floating_border pixel 2
      floating_modifier $mod normal

      # --- INPUT DEVICES ---
      input "type:touchpad" {
          tap enabled
          natural_scroll enabled
      }

      input type:keyboard xkb_options "ctrl:nocaps"

      seat * hide_cursor 3000

      # --- IDLE & LOCKING ---
      exec swayidle -w \
            timeout 300 'sh -c "pidof hyprlock || hyprlock"' \
            timeout 400 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            before-sleep 'sh -c "pidof hyprlock || hyprlock"'

      # --- KEYBINDINGS ---
      bindsym $mod+q exec $term

      bindsym $mod+Escape exec hyprlock

      bindsym $mod+v exec pkill -f "[a]pp-id=cliphist-menu" || $term --app-id="cliphist-menu" -e cliphist-menu

      bindsym XF86MonBrightnessUp exec brightnessctl set +5%
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

      bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +1%
      bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -1%
      bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
      
      # Use custom scripts instead of the default Sway commands!
      bindsym $mod+c exec sway-smart-kill
      bindsym $mod+Space exec sway-smart-float


      # Workspaces
      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9

      # Move windows
      bindsym $mod+Shift+1 exec sway-smart-move 1
      bindsym $mod+Shift+2 exec sway-smart-move 2
      bindsym $mod+Shift+3 exec sway-smart-move 3
      bindsym $mod+Shift+4 exec sway-smart-move 4
      bindsym $mod+Shift+5 exec sway-smart-move 5
      bindsym $mod+Shift+6 exec sway-smart-move 6
      bindsym $mod+Shift+7 exec sway-smart-move 7
      bindsym $mod+Shift+8 exec sway-smart-move 8
      bindsym $mod+Shift+9 exec sway-smart-move 9

      # Move through windows
      bindsym $mod+h focus left
      bindsym $mod+j focus down
      bindsym $mod+k focus up
      bindsym $mod+l focus right

      # Resize windows (while holding the modifier)
      bindsym $mod+Shift+h resize shrink width 10px
      bindsym $mod+Shift+j resize grow height 10px
      bindsym $mod+Shift+k resize shrink height 10px
      bindsym $mod+Shift+l resize grow width 10px

      # Move windows (while holding the modifier)
      bindsym $mod+Ctrl+h move left
      bindsym $mod+Ctrl+j move down
      bindsym $mod+Ctrl+k move up
      bindsym $mod+Ctrl+l move right

      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'
    '';
    };
  };
}

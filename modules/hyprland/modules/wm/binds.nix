{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mainMod, Q, exec, $terminal"
      "$mainMod, C, killactive,"
      "$mainMod, R, exec, $menu"
      "$mainMod, A, exec, $browser"
      "$mainMod, E, exec, $fileManager"

      "$mainMod, G, exec, wall-menu"
      "$mainMod SHIFT, G, exec, theme-switcher ~/Pictures/Wallpapers"

      "$mainMod, C, killactive"
      "$mainMod, M, exit"
      "$mainMod, V, togglefloating"
      "$mainMod, P, pseudo" # dwindle
      "$mainMod, J, togglesplit" # dwindle

      # Move focus with mainMod + arrow keys
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Move Windows with mainMod + ctrl + arrow keys
      "$mainMod Control_L, left, movewindow, l"
      "$mainMod Control_L, right, movewindow, r"
      "$mainMod Control_L, up, movewindow, u"
      "$mainMod Control_L, down, movewindow, d"
      "$mainMod Control_L, left, movewindow, l"

      # Fullscreen
      "$mainMod, f, fullscreen, 1"

      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"

      "$mainMod, comma, workspace, m-1"
      "$mainMod, period, workspace, m+1"

      "$mainMod, T, workspace, emptym"
      "$mainMod SHIFT, T, movetoworkspace, emptym"

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      # Special workspace (scratchpad)
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"

      # Scroll through existing workspaces with mainMod + scroll
      "$mainMod, mouse_down, workspace, m+1"
      "$mainMod, mouse_up, workspace, m-1"

      # Lock Session
      "$mainMod, L, exec, loginctl lock-session"

      # Restart waybar
      "$mainMod, N, exec, systemctl --user restart waybar"

      # Open SwayNC
      "$mainMod, H, exec, swaync-client -t -sw"

      # Power Off menu
      ", XF86PowerOff, exec, wlogout -b 5"

      # Screenshot
      ", Print, exec, grim -g \"$(slurp)\" - | satty --filename -"
      "$mainMod, Z, exec, grim -g \"$(slurp)\" - | satty --filename -"
    ];

    binde = [
      # Resizing Windows
      "$mainMod SHIFT, left, resizeactive, -10 0"
      "$mainMod SHIFT, right, resizeactive, 10 0"
      "$mainMod SHIFT, up, resizeactive, 0 -10"
      "$mainMod SHIFT, down, resizeactive, 0 10"

      # Brightness Control
      ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

      # Volume Control
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
    ];

    bindm = [
      # Move/resize windows with mainMod + LMB/RMB and dragging
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    bindl = [
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };
}

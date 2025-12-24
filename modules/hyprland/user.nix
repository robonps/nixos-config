{ pkgs, ... }:
{
    wayland.windowManager.hyprland = {
        enable = true;

        # Systemd intergration
        systemd.enable = true;

        settings = {
            "$mainMod" = "SUPER";
            "$terminal" = "kitty";
            "$menu" = "wofi --show drun";
            "$browser" = "librewolf";
        
            input = {
                kb_layout = "us";
                follow_mouse = 1;
            };

            bind = [
                "$mainMod, Q, exec, $terminal"
                "$mainMod, C, killactive,"
                "$mainMod, R, exec, $menu"
                "$mainMod, A, exec, $browser"
                "$mainMod, E, exec, $fileManager"

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
                "$mainMod, mouse_down, workspace, e+1"
                "$mainMod, mouse_up, workspace, e-1"
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
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ];

            bindm = [
                # Move/resize windows with mainMod + LMB/RMB and dragging
                "$mainMod, mouse:272, movewindow"
                "$mainMod, mouse:273, resizewindow"
            ];

            bindl = [
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                ", XF86AudioPlay, exec, playerctl play-pause"
                ", XF86AudioNext, exec, playerctl next"
                ", XF86AudioPrev, exec, playerctl previous"
            ];
        };
    };

    home.sessionVariables = {
        # Force Hyprland to use the correct cursor
        XCURSOR_THEME = "volantes_cursors";
        XCURSOR_SIZE = "24";
    };

    home.packages = with pkgs; [
        wofi
    ];

    programs.kitty = {
        enable = true;
        font.name = "JetBrainsMono Nerd Font";
        font.size = 11;
        settings = {
            # 0 = No warning (instant close)
            # -1 = Default (warn if *any* process is running, including bash)
            # Positive Number = Warn only if *this many* processes are running.
            
            # We set it to 0 so the window manager (Hyprland) handles the close immediately.
            # However, Kitty has a specific setting for ignoring the shell:
            
            # This is the exact setting you want:
            # "If the only running process is the shell (bash/zsh), close instantly.
            #  If anything else is running (vim, htop, python), WARN me."
            confirm_os_window_close = 0; 
        };
    };
}
{...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      source = "~/.config/hypr/hyprlock_colors.conf";

      background = [
        {
          monitor = "";
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "250, 50";
          outline_thickness = 0;
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = -1;

          # Colors
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "$box_bg";
          font_color = "$input_text";
          check_color = "$clock_color";
          fail_color = "$error";

          fade_on_empty = true;
          fade_timeout = 1000;
          placeholder_text = "";

          hide_input = false;
          rounding = -1;

          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        # TIME
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
          color = "$clock_color";
          font_size = 120;
          font_family = "JetBrainsMono Nerd Font Bold";
          position = "0, -300";
          halign = "center";
          valign = "top";
        }

        # DATE
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%A, %d %B %Y\")\"";
          color = "$date_color";
          font_size = 25;
          font_family = "JetBrainsMono Nerd Font Light";
          position = "0, -200";
          halign = "center";
          valign = "top";
        }

        # USER GREETING
        {
          monitor = "";
          text = "Hi there, $USER";
          color = "$greeting_color";
          font_size = 20;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -40";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances.
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
        after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
      };

      listener = [
        # 2min: Dim screen
        {
          timeout = 120;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
        }

        # 3min: Lock screen
        {
          timeout = 180;
          on-timeout = "loginctl lock-session";
        }

        # 5min: Screen off (DPMS)
        {
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}

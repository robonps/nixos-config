{ config, ... } : {
  
programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        ignore_empty_input = true;
        no_fade_in = true; # Snaps instantly to black, no animations
        no_fade_out = true; # Snaps instantly back to the screen, no animations
      };

      animations = {
        enabled = false;
      };

      # 1. Pitch Black Background
      background = [
        {
          monitor = "";
          path = "";
          color = "rgb(0, 0, 0)";
        }
      ];

      # 2. The Static Text Prompt
      label = [
        # 1. The Time
        {
          monitor = "";
          text = "$TIME⠀⠀⠀⠀";
          color = "rgb(255, 255, 255)";
          font_size = 14;
          font_family = config.font;
          # Shifted further left (-66) to visually align with the longer password string
          # Shifted up (30) to sit directly above the prompt
          position = "-50, 20"; 
          halign = "center";
          valign = "center";
        }
        
        # 2. The Password Prompt
        {
          monitor = "";
          text = "password:";
          color = "rgb(255, 255, 255)";
          font_size = 14;
          font_family = config.font;
          position = "-50, 0"; 
          halign = "center";
          valign = "center";
        }
      ];

      # 3. The Invisible Typing Box
      input-field = [
        {
          monitor = "";
          size = "300, 30";
          # Position it directly to the right of the label
          position = "150, 0"; 
          halign = "center";
          valign = "center";

          dots_rounding = 0; 
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = false;
          
          # Make the box itself completely invisible
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0)";
          font_color = "rgb(255, 255, 255)";
          
          fade_on_empty = false;
          placeholder_text = ""; # Remove default "Input Password..." text
          outline_thickness = 0;


          check_color = "rgba(0, 0, 0, 0)";
          fail_color = "rgba(0, 0, 0, 0)";
          capslock_color = "rgba(0, 0, 0, 0)";

          fail_text = "<span rise='-15000' font_family='${config.font}' font_size='12pt'>incorrect password</span>";
          fail_timeout = 2000;
          fail_transition = 0; # Snaps instantly, no color blending
        }
      ];
    };
  }; 

}
{
  pkgs,
  config,
  ...
}: {
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

      cursor_trail = 3;

      scrollback_lines = 5000;

      mouse_hide_wait = -3.0;
    };
    extraConfig = ''
      include ${config.xdg.cacheHome}/matugen/colors-kitty.conf
    '';
  };
}

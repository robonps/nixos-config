{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    sysstat

    upower
  ];
  programs.tmux = {
    enable = true;
    baseIndex = 1;

    escapeTime = 0; # Instant response to key combos

    keyMode = "vi"; # Use vi-style keybindings in copy mode

    plugins = with pkgs.tmuxPlugins; [
      cpu
      battery
      vim-tmux-navigator
    ];

    extraConfig = builtins.readFile ./tmux.conf + ''
      run-shell "${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux"
      run-shell "${pkgs.tmuxPlugins.battery}/share/tmux-plugins/battery/battery.tmux"
    '';
  };
}

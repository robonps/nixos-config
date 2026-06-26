{ config, pkgs, ... }:

let

  battery-script = pkgs.writeShellScriptBin "tmux-battery-weighted" ''
    total_now=0
    total_full=0

    for bat in /sys/class/power_supply/BAT*; do
        if [ -d "$bat" ]; then
            if [ -f "$bat/energy_now" ]; then
                total_now=$((total_now + $(cat "$bat/energy_now")))
                total_full=$((total_full + $(cat "$bat/energy_full")))
            elif [ -f "$bat/charge_now" ]; then
                total_now=$((total_now + $(cat "$bat/charge_now")))
                total_full=$((total_full + $(cat "$bat/charge_full")))
            fi
        fi
    done

    if [ "$total_full" -gt 0 ]; then
        percent=$(( 100 * total_now / total_full ))
        # Note: ''${...} is used here to escape Nix string interpolation
        echo "''${percent}%"
    else
        echo "N/A"
    fi
  '';
  network-script = pkgs.writeShellScriptBin "tmux-network-name" ''
    iface=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1 {print $5}')
    
    if [ -z "$iface" ]; then
        # Internet is down. Check if the Wi-Fi radio is actually on.
        if ${pkgs.networkmanager}/bin/nmcli radio wifi 2>/dev/null | grep -q "enabled"; then
            echo "(?_?) No Network"
        else
            echo "(x_x) Wi-Fi Off"
        fi
        exit 0
    fi

    ssid=$(${pkgs.wirelesstools}/bin/iwgetid -r "$iface" 2>/dev/null)

    if [ -n "$ssid" ]; then
        echo "$ssid ($iface)"
    else
        echo "Wired ($iface)"
    fi
  '';
in
{

  home.packages = with pkgs; [
    sysstat

    upower

    battery-script
    network-script
  ];
  programs.tmux = {
    enable = true;
    baseIndex = 1;

    escapeTime = 0; # Instant response to key combos

    keyMode = "vi"; # Use vi-style keybindings in copy mode

    plugins = with pkgs.tmuxPlugins; [
      cpu
      vim-tmux-navigator
    ];

    extraConfig = builtins.readFile ./tmux.conf + ''
      run-shell "${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/cpu.tmux"
    '';
  };
}

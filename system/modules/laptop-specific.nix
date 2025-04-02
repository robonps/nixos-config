{ config, pkgs, ... }: {
  
  # Configure audio services
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # For Jack applications
  };

  # Enable Thunderbolt support
  services.hardware.bolt.enable = true;

  # Enable Tailscale for remote connections
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

}

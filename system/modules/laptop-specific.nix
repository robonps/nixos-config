{ config, pkgs, ... }: {
  
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # For Jack Applications
    jack.enable = true;
  };

  services.hardware.bolt.enable = true;

}

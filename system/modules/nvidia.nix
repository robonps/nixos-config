{ pkgs, ... }: {
    
    # Enable OpenGL
    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [nvidia-vaapi-driver];
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaSettings = true;

        powerManagement.enable = true;
    };
}

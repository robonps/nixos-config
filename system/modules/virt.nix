{ config, pkgs, ... }:

{
    programs.virt-manager.enable = true;

    users.groups.libvirtd.members = ["robert"];

    virtualisation.libvirtd = { 
        enable = true;
        networks.default.autostart = true;
    };

    virtualisation.spiceUSBRedirection.enable = true;
}

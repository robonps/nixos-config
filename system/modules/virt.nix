{ config, pkgs, ... }:

{
    # Enable Virt-Manager
    programs.virt-manager.enable = true;

    # Add user to libvirtd group
    users.groups.libvirtd.members = ["robert"];

    # Enable libvirtd and SPICE USB redirection
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
}

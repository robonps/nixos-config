{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
    };
  };
  
  # Install virt-manager and enable its configuration
  programs.virt-manager.enable = true;

  # Add your user to the 'libvirtd' group
  # Replace 'yourusername' with your actual username
  users.users.robert.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    dnsmasq
  ];
}
{...}:
{
  services.openssh = {
    enable = true;
    
    # Security: Disable passwords, require SSH keys
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
}
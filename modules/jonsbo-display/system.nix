{pkgs, ...}: let
  display = pkgs.callPackage ./package.nix {};
in {
  users.groups.jonsbo-display = {};

  # Access survives reboot and hidraw renumbering without a manual ACL.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="5131", ATTRS{idProduct}=="2007", GROUP="jonsbo-display", MODE="0660"
  '';

  systemd.services.jonsbo-display = {
    description = "Jonsbo CPU temperature display";
    wantedBy = ["multi-user.target"];
    after = ["systemd-udev-trigger.service"];
    # Retry while unplugged, including if the device is absent at boot.
    startLimitIntervalSec = 0;
    serviceConfig = {
      ExecStart = "${display}/bin/jonsbo-display";
      DynamicUser = true;
      # The dynamic account must not collide with the permanent USB-access group.
      User = "jonsbo-updater";
      SupplementaryGroups = ["jonsbo-display"];
      Restart = "on-failure";
      RestartSec = 5;
      DevicePolicy = "closed";
      DeviceAllow = ["char-hidraw w"];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateNetwork = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      CapabilityBoundingSet = "";
      UMask = "0077";
    };
  };
}

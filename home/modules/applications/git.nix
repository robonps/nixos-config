{ pkgs, ... }: {

    programs.git = {
        enable = true; # Enable Git
        userName = "Robert"; # Set the Git username
        userEmail = "git@robonps.com"; # Set the Git email
    };

}
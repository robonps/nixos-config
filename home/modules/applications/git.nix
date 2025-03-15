{ pkgs, ... }: {

    programs.git = {
        enable = true;
        userName = "Robert";
        userEmail = "git@robonps.com";
    };

}
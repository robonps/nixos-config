{ defaults, ... }: {
    hostname = builtins.getEnv "HOSTNAME";

    desktopEnvironment = let 
        env = builtins.getEnv "DESKTOP_ENVIRONMENT";
    in if env != "" then env else defaults.desktopEnvironment;

    theme = builtins.getEnv "THEME";

    enabledModules = builtins.getEnv "ENABLED_MODULES"; 
}

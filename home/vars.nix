{ defaults, ... }: {
    # Get the hostname from the environment
    hostname = builtins.getEnv "HOSTNAME";

    # Determine the desktop environment, falling back to default if not set
    desktopEnvironment = let 
        env = builtins.getEnv "DESKTOP_ENVIRONMENT";
    in if env != "" then env else defaults.desktopEnvironment;

    # Get the theme from the environment
    theme = builtins.getEnv "THEME";

    # Get enabled modules from the environment
    enabledModules = builtins.getEnv "ENABLED_MODULES"; 
}

{ pkgs, ... }: {
    # Packages for study-related tasks
    home.packages = with pkgs; [
        ciscoPacketTracer8
    ];
}
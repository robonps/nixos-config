{ pkgs, ...}:

{
  programs.beets = {
    enable = true;

    # This wraps beets with the extra python libraries it needs
    package = pkgs.beets.override {
      python3 = pkgs.python3.withPackages (ps: with ps; [
        # Replaygain (gstreamer) dependencies
        pygobject3

        # Acoustid plugin dependencies
        pyacoustid
      ]);
    };

    settings = {
      directory = "~/Music/Library/Music";
      library = "~/Music/Library/library.db";

      plugins = [
        "lyrics"
        "lastgenre"
        "chroma"
        "spotify"
        "deezer"
        "replaygain"
      ];

      import = {
        move = true;
        write = true;
      };

      lyrics = {
        sources = [ "lrclib" "genius" "tekstowo" ];
        synced = true;
      };

      replaygain = {
        backend = "gstreamer";
      };

      threaded = true;

      paths = {
        default = "$albumartist/$album%aunique{}/$track $title ($bitrate)";
        singleton = "Non-Album/$artist/$title ($bitrate)";
        comp = "Compilations/$album%aunique{}/$track $title ($bitrate)";
      };
    };
  };
}
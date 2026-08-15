{ config, ... }: {
  programs.tofi = {
    enable = true;

    settings = {
      font = config.font;
      font-size = 14;

      width = 500;
      height = 180;
      anchor = "center";

      # Terminal-like palette
      background-color = "#000000";
      text-color = "#ffffff";

      # Very subtle terminal/window boundary
      border-width = 1;
      border-color = "#3a3a3a";
      outline-width = 0;
      corner-radius = 0;

      # Prompt/input
      prompt-text = "exec: ";
      prompt-color = "#ffffff";
      prompt-padding = 0;
      input-color = "#ffffff";

      # Results
      num-results = 5;
      result-spacing = 3;

      default-result-color = "#808080";
      selection-color = "#ffffff";
      selection-match-color = "#ffffff";

      # Layout
      padding-top = 12;
      padding-bottom = 12;
      padding-left = 16;
      padding-right = 16;

      # Terminal behaviour
      hide-cursor = true;

      text-cursor = true;
      text-cursor-style = "block";
      text-cursor-color = "#ffffff";
      text-cursor-background = "#000000";

      history = true;

      fuzzy-match = true;

      drun-launch = true;
    };
  };
}
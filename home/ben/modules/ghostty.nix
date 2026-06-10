{ config, ... }:
{
  programs.ghostty = {
    settings = {
      confirm-close-surface = false;
      background-opacity = 0.75;
      background-blur-radius = 30;
      font-family = config.sysFonts.mono.name;
    };
    enable = true;
  };
}

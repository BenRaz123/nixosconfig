{ config, ... }:
{
  programs.ghostty = {
    settings = {
      confirm-close-surface = false;
      font-family = config.sysFonts.mono.name;
      theme = "dark:Gruvbox Dark Hard, light:Adwaita";
    };
    enable = true;
  };
}

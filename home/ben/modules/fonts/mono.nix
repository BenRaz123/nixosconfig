{ pkgs, ... }:
{
  sysFonts.mono = {
    pkg = pkgs.nerd-fonts.adwaita-mono;
    name = "AdwaitaMono Nerd Font";
  };
}

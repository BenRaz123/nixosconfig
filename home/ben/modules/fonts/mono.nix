{ pkgs, ... }:
{
  sysFonts.mono = {
    pkg = pkgs.nerd-fonts.cousine;
    name = "Cousine Nerd Font";
  };
}

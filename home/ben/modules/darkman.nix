{ pkgs, ... }:
{
  services.darkman = {
    enable = true;
    lightModeScripts.gtk-theme = ''
      ${pkgs.dconf}/bin/dconf write \
          /org/gnome/desktop/interface/color-scheme "'prefer-light'"
    '';
    darkModeScripts.gtk-theme = ''
      ${pkgs.dconf}/bin/dconf write \
          /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
    '';
    settings = {
      usegeoclue = true;
      dbusserver = true;
      portal = true;
    };
  };
}

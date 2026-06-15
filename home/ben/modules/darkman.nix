{ pkgs, ... }:
{
  services.darkman = {
    enable = true;
    lightModeScripts.gtk-theme = ''
      ${pkgs.dconf}/bin/dconf write \
          /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-light" # for gtk3 apps
    '';
    darkModeScripts.gtk-theme = ''
      ${pkgs.dconf}/bin/dconf write \
          /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark" # for gtk3 apps
    '';
    settings = {
      usegeoclue = true;
      dbusserver = true;
      portal = true;
    };
  };
}

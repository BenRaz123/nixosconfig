{
  keys,
  lib,
  pkgs,
  scripts,
  utils,
  ...
}:
let
  inherit (lib) run;

  inherit (utils)
    shell
    ;
  inherit (keys)
    mod
    ;

  inherit (scripts)
    browser
    desktopMenu
    menuRun
    passMenu
    term
    ;
in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+Return" = "exec ${term}";
    "${mod}+Shift+Return" = "exec ${browser}";
    "${mod}+Shift+f" = "exec ${desktopMenu}";
    "${mod}+d" = "exec ${menuRun}";
    "${mod}+Shift+s" = "exec ${run pkgs.bash} -c 'systemctl sleep; ${run pkgs.swaylock}'";
    "${mod}+Backslash" = "exec ${run pkgs.shotman} -Cc region";
    "${mod}+c" = "exec makoctl dismiss -a";
    "${mod}+p" = "exec ${shell passMenu}";
  };
}

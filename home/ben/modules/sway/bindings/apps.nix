{
  keys,
  scripts,
  utils,
  ...
}:
let
  inherit (utils)
    use
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
    "${mod}+Shift+s" = "exec ${use "bash"} -c 'systemctl sleep; ${use "swaylock"}'";
    "${mod}+Backslash" = "exec ${use "shotman"} -Cc region";
    "${mod}+c" = "exec makoctl dismiss -a";
    "${mod}+p" = "exec ${shell passMenu}";
  };
}

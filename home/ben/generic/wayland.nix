{
  pkgs,
  osConfig,
  ...
}:
throw osConfig.programs.sway.enable
#let
#  inherit (pkgs) lib;
#  browser = "qutebrowser";
#in
#{
#  wayland.windowManager.sway = {
#    enable = osConfig.programs.sway.enable;
#    wrapperFeatures.gtk = true;
#    config = {
#      bindswitches = {
#        "lid:on" = {
#          reload = true;
#          locked = true;
#          action = "output eDP-1 disable";
#        };
#        "lid:off" = {
#          reload = true;
#          locked = true;
#          action = "output eDP-1 enable";
#        };
#      };
#      keybindings =
#        let
#          modifier = "Mod4";
#        in
#        lib.mkOptionDefault {
#          "${modifier}+q" = "kill";
#          "${modifier}+Shift+Return" = "exec ${browser}";
#          "${modifier}+Return" = "exec foot";
#        };
#    };
#  };
#}

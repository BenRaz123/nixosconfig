{ keys, ... }:
let
  inherit (keys)
    mod
    ;
in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+s" = "layout stacking";
    "${mod}+w" = "layout tabbed";
    "${mod}+e" = "toggle split";

    "${mod}+Shift+Space" = "floating toggle";
    "${mod}+Space" = "focus mode_toggle";
    "${mod}+a" = "focus parent";
  };
}

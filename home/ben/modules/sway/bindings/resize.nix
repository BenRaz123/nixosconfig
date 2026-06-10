{ keys, ... }:
let
  inherit (keys)
    left
    right
    up
    down

    mod
    ;
in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+r" = "mode 'resize'";
  };

  wayland.windowManager.sway.config.modes.resize = {
    ${left} = "resize shrink width 10px";
    ${right} = "resize grow width 10px";

    ${up} = "resize shrink height 10px";
    ${down} = "resize grow height 10px";
    Return = "mode default";
    Escape = "mode default";
  };
}

{
  wayland.windowManager.sway.config = {
    bindswitches."lid:on" = {
      reload = true;
      locked = true;
      action = "output eDP-1 disable";
    };
    bindswitches."lid:off" = {
      reload = true;
      locked = true;
      action = "output eDP-1 enable";
    };
  };
}

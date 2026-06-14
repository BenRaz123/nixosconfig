{
  config,
  keys,
  lib,
  utils,
  ...
}:
let
  inherit (utils)
    use
    ;

  inherit (keys)
    mod
    ;
in

lib.mkIf config.services.darkman.enable {
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+t" = "exec ${use "darkman"} toggle";
  };
}

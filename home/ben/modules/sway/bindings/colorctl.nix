{
  keys,
  pkgs,
  scripts,
  utils,
  ...
}:
let
  inherit (utils)
    shell
    use
    ;

  inherit (keys)
    mod
    ;

  inherit (scripts)
    notify
    ;

  toggle = pkgs.writeShellScript "toggle dark mode" ''
    ${notify "Changed Color Scheme To $(colorctl toggle)"}
  '';

in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+t" = "exec ${shell toggle}";
  };
}

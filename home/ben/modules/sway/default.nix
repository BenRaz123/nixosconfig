{
  imports = [
    ./appearance.nix
    ./bars.nix
    ./colorUtil.nix
    ./colors.nix
    ./consts.nix
    ./scripts.nix
    ./utils.nix
    ./windows.nix
    ./misc.nix

    ./bindings
  ];

  wayland.windowManager.sway = {
    enable = true;
  };
}

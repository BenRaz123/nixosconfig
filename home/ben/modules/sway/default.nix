{
  imports = [
    ./appearance.nix
    ./bars.nix
    ./colorUtil.nix
    ./colors.nix
    ./consts.nix
    ./layouts.nix
    ./misc.nix
    ./scripts.nix
    ./utils.nix
    ./windows.nix

    ./bindings
  ];

  wayland.windowManager.sway = {
    enable = true;
  };
}

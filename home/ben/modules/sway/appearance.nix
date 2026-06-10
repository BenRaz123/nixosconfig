{
  config,
  colors,
  pkgs,
  ...
}:
let
  inherit (colors)
    accentColor
    bgcolor
    ;

  bg = import ./bgpic.nix { inherit pkgs; };

  defaultColors = {
    background = "#285577";
    border = "#4c7899";
    childBorder = "#285577";
    indicator = "#2e9ef4";
    text = "#ffffff";
  };
in
{
  wayland.windowManager.sway.config = {
    fonts = {
      names = [ config.sysFonts.normal.name ];
      style = "Regular";
      size = 12.0;
    };
    colors = {
      focused = defaultColors // {
        background = accentColor;
        border = accentColor;
        text = bgcolor;
        childBorder = accentColor;
      };
      unfocused = defaultColors // {
        background = bgcolor;
        border = "#1f2337";
        text = "#A6ACCD";
        childBorder = bgcolor;
      };
    };
    output."*".bg = "${bg} fill";
  };
}

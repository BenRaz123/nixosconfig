{
  config,
  colors,
  ...
}:
let
  inherit (colors)
    accentColor
    accentBorder
    bgcolor
    ;
  secs = n: "${toString (1000 * n)}";
in
{
  services.mako = {
    enable = true;
    settings = {
      default-timeout = secs 4;
      font = config.sysFonts.normal.name + " 12";
      layer = "overlay";
      text-color = bgcolor;
      background-color = accentColor;
      border-color = accentBorder;
      max-visible = 10;
    };
  };
}

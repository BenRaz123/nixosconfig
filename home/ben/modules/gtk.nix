{ config, ... }:
let
  font = config.sysFonts.normal;
in
{
  gtk = {
    enable = true;
    font = {
      inherit (font) name;
      size = 11;
      package = font.pkg;
    };
  };
}

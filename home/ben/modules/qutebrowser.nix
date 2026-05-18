{ config, pkgs, ... }:
let
  font = config.sysFonts.normal;
in
{
  programs.qutebrowser = {
    enable = true;
    searchEngines = {
      DEFAULT = "https://google.com/search?q={}";

      noogle = "https://noogle.dev/q/?term={}";
      osopt = "https://search.nixos.org/options?channel=unstable&query={}";
      pkgs = "https://search.nixos.org/packages?channel=unstable&query={}";
    };
    settings = {
      url.default_page = "https://google.com";
      fonts.default_family = "${font.name} Light";
      fonts.default_size = "13pt";
      content.user_stylesheets = "${pkgs.writeText "qute-stylesheet.css" ''
        *:not(
          i, i *,
          pre, pre *,
          code, code *,
          textarea, textarea *,
          .editor, .editor *
        ) {
          font-family: "${font.name}" !IMPORTANT;
          border-radius: 0 !IMPORTANT;
        }
      ''}";
    };
  };
}

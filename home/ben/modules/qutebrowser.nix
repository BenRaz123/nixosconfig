{
  config,
  lib,
  pkgs,
  ...
}:
let
  font = config.sysFonts.normal;

  mkStylesheet =
    excludes:
    let
      ancestors = map (exclude: "${exclude}, ${exclude} *") excludes;
    in
    pkgs.writeText "qute-stylesheet.css" ''
      *:not(${lib.concatStringsSep ", " ancestors}) {
        font-family: "${font.name}" !IMPORTANT;
        border-radius: 0 !IMPORTANT;
      }
      textarea, textarea * {
        font-family: monospace !IMPORTANT;
      }
    '';
in
{
  programs.qutebrowser = {
    enable = true;
    searchEngines = {
      DEFAULT = "https://google.com/search?q={}";

      noogle = "https://noogle.dev/q/?term={}";
      osopt = "https://search.nixos.org/options?channel=unstable&query={}";
      pkgs = "https://search.nixos.org/packages?channel=unstable&query={}";
      hm = "https://home-manager-options.extranix.com/?release=master&query={}";
    };
    settings = rec {
      url.default_page = "https://google.com";
      url.start_pages = [ url.default_page ];
      qt.force_platformtheme = "gtk3";
      fonts.default_family = "${font.name} Light";
      fonts.default_size = "13pt";
      fonts.web.family.fixed = "${config.sysFonts.mono.name}";
      content.user_stylesheets = "${mkStylesheet [
        "i"
        "pre"
        "code"
        "textarea"
        ".editor"
        "mat-icon"
        ''[role="img"]''
        ''[data-button-type="ICON"]''
        "span.google-symbols"
        "span.material-symbols-outlined"
        ".view-line > span"
      ]}";
    };
  };
}

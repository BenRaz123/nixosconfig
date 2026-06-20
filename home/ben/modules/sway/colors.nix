{ lib, ... }:
let
  inherit (lib.colorUtil)
    darkenBy
    ;
in
{
  _module.args.colors = rec {
    accentColor = "#89DDFF";
    bgcolor = "#0E1019";

    accentBorder = darkenBy 10 accentColor;
    unfocusedText = "#a6accd";
    unfocusedBorder = "#1f2337";
  };
}

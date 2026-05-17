{ pkgs }:
let
  trimVersion = version: builtins.replaceStrings [ "." ] [ "" ] version;
in
{
  pkg = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "Route 159";
    version = "1.10";

    src = pkgs.fetchzip {
      url = "https://www.dotcolon.net/files/fonts/route159_${trimVersion finalAttrs.version}.zip";
      hash = "sha256-1InyBW1LGbp/IU/ql9mvT14W3MTxJdWThFwRH6VHpTU=";
      stripRoot = false;
    };

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp *.otf $out/share/fonts/truetype
    '';
  });
  name = "Route 159";
}

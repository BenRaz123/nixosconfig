{
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    #package = pkgs.git.overrideAttrs (old: rec {
    #  version = "2.55.0";

    #  src = pkgs.fetchurl {
    #    url =
    #      if lib.strings.hasInfix "-rc" version then
    #        "https://www.kernel.org/pub/software/scm/git/testing/git-${
    #          builtins.replaceStrings [ "-" ] [ "." ] version
    #        }.tar.xz"
    #      else
    #        "https://www.kernel.org/pub/software/scm/git/git-${version}.tar.xz";
    #    hash = "sha256-RX/bBNyHKOAH1GiGleaRLm9oByeSDypAvxHqzBdQU1c=";
    #  };
    #});
    settings = {
      user.name = "BenRaz123";
      user.email = "ben.raz2008@gmail.com";
    };
  };
}

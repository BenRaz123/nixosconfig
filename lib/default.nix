{pkgs, lib}@args:
{
  run = pkg: "${pkg}/bin/${lib.getName pkg}";
  colorUtil = import ./colorUtil.nix args;
}

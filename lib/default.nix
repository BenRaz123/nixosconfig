{ pkgs, lib }@args:
{
  # deprecated alias
  #run = pkg: "${pkg}/bin/${lib.getName pkg}";
  run = lib.getExe;
  colorUtil = import ./colorUtil.nix args;
  awk = import ./awk.nix args;
}

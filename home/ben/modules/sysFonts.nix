{ lib, config, ... }:
{
  options.sysFonts = with lib; {
    normal.name = mkOption { type = types.str; };
    normal.pkg = mkOption { };

    mono.name = mkOption { type = types.str; };
    mono.pkg = mkOption { };
  };

  config.home.packages = with config.sysFonts; [
    normal.pkg
    mono.pkg
  ];
}

{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    ;

  inherit (lib.types)
    listOf
    submodule
    str
    bool
    ;

  cfg = config.symlinks;

  symlinkType.options = {
    source = mkOption { type = str; };
    destination = mkOption { type = str; };
    override = mkOption {
      type = bool;
      default = true;
      description = "whether to override the link destination if it exists. equivalent to L+ as opposed to L. See the manpage.";
    };
  };
in
{
  options.symlinks = mkOption {
    description = "files to symlink with systemd-tmpfiles.d";
    type = listOf (submodule symlinkType);
  };
  config.systemd.tmpfiles.rules = map (
    {
      source,
      destination,
      override,
    }:
    "L${lib.optionalString override "+"} ${destination} - - - - ${source}"
  ) cfg;
}

{
  pkgs,
  lib,
  ...
}:
let
  mkBool =
    default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
    };
in
{
  options.settings = {
    shell = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.bash}/bin/bash";
    };
    org.enable = mkBool false;
    org.useDropbox = mkBool false;
    org.plannerCaptures = lib.mkOption {
      #      type = lib.types.attrsOf (lib.types.either (lib.types.attrsOf lib.types.str) (lib.types.str));
      description = "can either be an attrset of strings or a attrset of attrsets of strings";
      default = { };
    };

    TZ = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
    };

    VERSION = lib.mkOption {
      type = lib.types.str;
    };

    USER = lib.mkOption { type = lib.types.str; };

    TAB_WIDTH = lib.mkOption {
      type = lib.types.ints.u8;
      default = 4;
    };
  };
}

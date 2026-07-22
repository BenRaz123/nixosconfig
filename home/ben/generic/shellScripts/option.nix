{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption;

  inherit (lib.types)
    attrs
    attrsOf
    lines
    listOf
    package
    submodule
    ;

  cfg = config.shellScripts;

  mkShellScript =
    {
      name,
      text,
      shell,
      env,
      path,
    }:
    let
      env' = lib.concatMapAttrsStringSep "" (k: v: ''
        ${lib.toShellVar k v}
        export ${k}
      '') env;
      path' = lib.optionalString (path != [ ]) ''export PATH="${lib.makeBinPath path}"'';
    in
    pkgs.writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = ''
        #!${lib.getExe shell}
        ${path'}
        ${env'}

        ${text}
      '';
      checkPhase = ''
        runHook preCheck
        ${lib.getExe pkgs.shellcheck} "$target"
        runHook postCheck
      '';
    };

  script = submodule {
    options = {
      shell = mkOption {
        type = package;
        default = config.shellScriptsMainShell;
        description = "specific shell to use for this script alone. must be supported by shellcheck";
      };
      text = mkOption {
        type = lines;
        description = "body of the script";
      };
      env = mkOption {
        type = attrs;
        default = { };
        description = "environment variables to be passed to the script";
      };
      path = mkOption {
        type = listOf package;
        default = [ ];
        description = "packages to be added to $PATH";
      };
    };
  };
in
{
  options.shellScriptsMainShell = mkOption {
    type = package;
    default = pkgs.dash;
    description = "default shell to use for shell scripts. can be overrided per-script. dash is recommended as it is fast but any shell supported by shellcheck should do.";
  };

  options.shellScripts = mkOption {
    type = attrsOf script;
    description = "scripts. name will be used as binary name";
    default = { };
  };

  config.home.packages = (
    lib.mapAttrsToList (
      name:
      {
        text,
        shell,
        env,
        path,
      }:
      mkShellScript {
        inherit
          name
          text
          shell
          env
          path
          ;
      }
    ) cfg
  );
}

{
  lib,
  pkgs,
  scripts,
  ...
}:
{
  _module.args.utils =
    let
      inherit (scripts)
        menu
        ;
    in
    rec {
      symAt = codepoint: builtins.fromJSON ''"\u${codepoint}"'';

      use = cmd: "${pkgs.${cmd}}/bin/${cmd}";

      shell = s: "$(${toString s})";

      settingsToCLI =
        settings@{ ... }:
        settings
        |> lib.mapAttrsToList (
          name: val:
          if val == true then
            "--${name}"
          else if val == false then
            ""
          else if builtins.isString val then
            "--${name}='${val}'"
          else
            "--${name}=${toString val}"
        )
        |> lib.concatStringsSep " ";

      shLock = name: ''
        exec {lock_fd}>"/tmp/''${0//\//-}${name}-SH-LOCK"
        flock -n "$lock_fd" || exit
      '';

      releaseLock = "exec {lock_fd}>&-";

      writeLockedScript =
        name: body:
        pkgs.writeShellScript name ''
          ${shLock name}
          ${body}
        '';

      mkMenu =
        name:
        { ... }@actions:
        writeLockedScript "${name}-menu" ''
          readonly opts=$(cat<<EOF
          ${actions |> builtins.attrNames |> lib.concatStringsSep "\n"}
          EOF
          )

          res=$(echo "$opts" | ${menu} -p "${name}>>")

          (($?)) && exit $?

          case "$res" in
          ${
            actions
            |> lib.mapAttrsToList (
              title: action: ''
                "${title}")
                  ${action}
                  ;;
              ''
            )
            |> lib.concatStringsSep "\n"
          }
          esac
        '';

      # Prepares a pango string
      preparePangoString =
        s:
        s
        |> builtins.replaceStrings [ "<" ">" ] [ "&lt;" "&gt;" ]
        |> builtins.replaceStrings [ "{{" "}}" ] [ "<" ">" ];

      # append a percent sign to a string
      percent = s: s + "%";
    };
}

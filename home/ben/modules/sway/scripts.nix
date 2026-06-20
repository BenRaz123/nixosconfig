{
  config,
  consts,
  lib,
  pkgs,
  utils,
  ...
}:
let
  inherit (consts)
    BAT
    ;

  inherit (lib)
    run
    ;

  inherit (pkgs)
    writeShellScript
    ;

  inherit (utils)
    mkMenu
    preparePangoString
    releaseLock
    settingsToCLI
    writeLockedScript
    ;
in
{
  _module.args.scripts = rec {
    doCmd =
      cmd:
      {
        ifFail ? ":",
        ifSuccess ? ":",
        pre ? ":",
        post ? ":",
        customName ? "running ${cmd}",
        ifEq ? { },
      }:
      writeShellScript customName ''
        ${pre}
        OUT=$(${cmd})
        RET="$?"
        ${
          ifEq
          |> lib.mapAttrsToList (
            k: v: ''
              if [[ "$OUT" =~ "${k}" ]]; then
                ${v}
              fi
            ''
          )
          |> lib.concatStringsSep "\n"
        }
        if [[ "$RET" == 0 ]]; then
          ${ifSuccess}
        else
          ${ifFail}
        fi
        ${post}
      '';

    term = "${run pkgs.ghostty} +new-window -e ${writeShellScript "tmux new window" ''
      readonly TMUX=${run pkgs.tmux}
      $TMUX a || $TMUX
    ''}";

    menuRun = ''${pkgs.bemenu}/bin/bemenu-run ${settingsToCLI config.programs.bemenu.settings} -p "run>>"'';

    menu = "${run pkgs.bemenu} ${settingsToCLI config.programs.bemenu.settings}";

    desktopMenu = ''${run pkgs.j4-dmenu-desktop} --dmenu="${menu}"'';

    browser = "qutebrowser";

    getBrt = writeShellScript "get brightness" ''
      echo "scale=0; ($(${run pkgs.brightnessctl} get)*100)/500" | ${run pkgs.bc}
    '';

    getKB = writeShellScript "getKB" ''
      swaymsg -t get_inputs \
        | ${run pkgs.jq} '.[].xkb_active_layout_name | select(. != null)' \
        | sort -u \
        | sed 's/"//g'
    '';

    getVol = writeShellScript "getVol" ''
      pactl -f json list sinks \
        | ${run pkgs.jq} '.[] 
          | select(.name == "'"$(pactl get-default-sink)"'") 
          | .volume 
          | .[].value_percent' \
        | uniq \
        | tr "\n" ' ' \
        | tr -d '"'
    '';

    getBat = writeShellScript "get battery" ''
      readonly RG=${run pkgs.ripgrep}
      upower -i ${BAT} \
        | $RG "percentage" \
        | $RG -o '([0-9]+)(?:\.?[0-9]+)' -r '$1'
    '';
    getBatCharging = writeShellScript "get charging state" ''
      readonly RG=${run pkgs.ripgrep}
      readonly info=$(upower -i ${BAT} \
        | $RG "state")
      if echo "$info" | $RG -q "discharging"; then
        echo "discharging"
        exit 0;
      fi
      if echo "$info" | $RG -q "charging"; then
        echo "charging"
        exit 0;
      fi
      if echo "$info" | $RG -q "pending"; then
        echo "pending"
        exit 0;
      fi
    '';

    pass = "${config.programs.password-store.package}/bin/pass";

    passMenu = writeLockedScript "passmenu" ''
      shopt -s nullglob globstar

      cd ~/.password-store/ || exit $?
      list=()

      for pw in ./**/*.gpg; do
        pw="''${pw#./}"
        pw="''${pw%.gpg}"
        list+=( "$pw" )
      done



      if ! sel=$(printf '%s\n' "''${list[@]}" | ${menu} -p "pass>>"); then
        exit "$?"
      fi

      # we need to release the lock because `pass` spawns a timer subprocess 
      ${releaseLock} 

      ${pass} -c "$sel"
    '';

    powerMenu = mkMenu "power" {
      Cancel = "exit";
      Lock = "swaylock";
      Reboot = "reboot";
      Suspend = "systemctl suspend";
      "Power Off" = "poweroff";
      Sleep = "systemctl sleep; ${run pkgs.swaylock}";
    };

    notify = msg: ''${run pkgs.zenity} --notification --text "${msg}"'';

    mkStatusCommand =
      args@{ main, ... }:
      let
        defaultLineAttrs = {
          markup = "pango";
        };
        lines =
          removeAttrs args [ "main" ]
          |> lib.mapAttrsToList (
            name: val:
            {
              inherit name;
              full_text = preparePangoString "<${lib.toUpper name} ${toString val}>";
            }
            // defaultLineAttrs
          );
        barLines = [
          (
            {
              full_text = preparePangoString "{{span color='#ffffff'}}{{b}}<<${main}>>{{/b}}{{/span}}";
              name = "main";
            }
            // defaultLineAttrs
          )
        ]
        ++ lines;

      in
      writeShellScript "statusbar" ''
        cat <<EOF
        ${builtins.toJSON {
          version = 1;
        }}
        [
        EOF
        FIRST=1
        while true; do
          (($FIRST)) || echo ","
          cat <<EOF
        ${builtins.toJSON barLines}
        EOF
          FIRST=0
          sleep 1
        done
        echo ]
      ''
      |> toString;
  };
}

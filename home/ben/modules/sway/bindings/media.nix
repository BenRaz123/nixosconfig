{
  lib,
  pkgs,
  keys,
  scripts,
  utils,
  ...
}:
let
  inherit (lib)
    run
    ;

  inherit (keys)
    mod
    ;

  inherit (scripts)
    menu
    notify
    getBrt
    ;

  inherit (utils)
    shell
    symAt
    ;

  inherit (pkgs)
    writeShellScript
    ;

  mprisValue =
    variable:
    {
      ifyes ? val: val,
      ifeq ? { },
      ifno ? "",
      player ? null,
    }:
    let
      cmd = if player != null then "${run pkgs.playerctl} -p ${player}" else "$(${getPlayerctlCommand})";
    in
    lib.strings.trim ''
      $({
        cmd=(${cmd})
        val="$("''${cmd[@]}" -f "{{${variable}}}" metadata)"

        not_matched=1

        ${
          lib.mapAttrsToList (match: result: ''
            if (($not_matched)) && [[ "$val" =~ "${match}" ]]; then
              printf '%s' "${result}"
              not_matched=0
            fi
          '') ifeq
          |> lib.concatStringsSep "\n"
        }

        if [[ -n "$val" ]]; then
          (($not_matched)) && printf '%s' "${ifyes "$val"}"
        else
          (($not_matched)) && printf '%s' "${ifno}"
        fi
      })
    '';
  playSym = symAt "25B8";
  pauseSym = symAt "23F8";

  status = mprisValue "status" {
    ifno = "(Unknown Pause/Play Status)";
    ifeq.Playing = "${playSym} Playing";
    ifeq.Paused = "${pauseSym} Paused";
  };

  title = mprisValue "title" {
    ifno = "<No Title>";
    ifyes = x: ''\"${x}\"'';
  };

  playerName = mprisValue "playerName" {
    ifno = "<No Player>";
  };

  author = mprisValue "artist" {
    ifyes = x: " [${x}]";
  };

  infofmt = ''
    ${title}${author}
    (${playerName})
  '';

  pcmd =
    action:
    {
      pre ? null,
      ifSuccess ? null,
      ifFail ? null,
    }:
    let
      optCmd = cmd: if cmd == null then ":" else cmd;
    in
    "${writeShellScript "mpris ${action}" ''
      ${optCmd pre}
      cmd=($(${getPlayerctlCommand}))
      if "''${cmd[@]}" "${action}"; then
        ${optCmd ifSuccess}
      else
        ${optCmd ifFail}
      fi
    ''}";

  toggle = pcmd "play-pause" {
    ifSuccess = notify ''
      ${status}
      ${infofmt}
    '';
    ifFail = notify "Nothing Playing";
  };

  stop = pcmd "stop" {
    pre = ''old="${infofmt}"'';
    ifSuccess = notify ''
      ${symAt "23F9"} Stopped 
      $old
    '';
  };

  ffSym = "${symAt "25B8"}${symAt "25B8"}";
  prevSym = "${symAt "25C2"}${symAt "25C2"}";

  ff = pcmd "next" {
    ifFail = notify ''
      ${ffSym} Could Not Fast Forward!
      Current Player: ${playerName}
    '';
    ifSuccess = notify ''
      ${ffSym} Fast Forward
      ${infofmt}
    '';
  };

  prev = pcmd "previous" {
    ifFail = notify ''
      ${prevSym} Could Not Go Back!
      Current Player: ${playerName}
    '';
    ifSuccess = notify ''
      ${prevSym} Previous
      ${infofmt}
    '';
  };

  infoSym = symAt "2139";

  info = pcmd "metadata" {
    ifFail = notify ''
      ${infoSym} Could not get info!
      Current Player: ${playerName}
    '';
    ifSuccess = notify ''
      ${infoSym}  ${title} (${
        mprisValue "status" {
          ifeq.Playing = playSym;
          ifeq.Paused = pauseSym;
        }
      })
      Artist: ${
        mprisValue "artist" {
          ifno = "<No Artist>";
        }
      }
      Album: ${
        mprisValue "album" {
          ifno = "<No Album>";
        }
      }
      (${playerName})
    '';
  };

  playerFolder = "$HOME/.cache/mpris-media-player";
  playerFile = "${playerFolder}/currentPlayer.txt";
  anyPlayer = "%any";

  getPlayerctlCommand = ''
    {
    playerCtl=${run pkgs.playerctl}
    selPlayer=${getPlayerFile}

    if [[ "$selPlayer" == "${anyPlayer}" ]]; then
      printf '%q\n' "$playerCtl"
    else
      found=0

    while read -r player; do
      if [[ "$player" == "$selPlayer" ]]; then
      found=1
      break
      fi
    done < <($playerCtl --list-all)

    if (($found)); then
      printf '%q %q %q\n' \
      "$playerCtl" \
      "-p" \
      "$selPlayer"
    else
      ${writePlayerFile anyPlayer}
      printf '%q\n' "$playerCtl"
    fi
    fi
    }
  '';

  getPlayerFile = ''
    $({
      mkdir -p ${playerFolder}
      touch ${playerFile}
      contents="$(cat "${playerFile}")"
      echo "''${contents:-${anyPlayer}}";
    })
  '';

  writePlayerFile = val: ''
    {
      printf '%s' "${val}" > "${playerFile}"
    }
  '';

  playerMenu =
    let
      mprisValue' = cmd: opts@{ ... }: mprisValue cmd (opts // { player = "$player"; });
      pname = mprisValue' "playerName" {
        ifyes = x: x;
        ifno = "$player";
      };

      status = mprisValue' "status" {
        ifno = "?";
        ifeq.Playing = playSym;
        ifeq.Paused = pauseSym;
      };
      title = mprisValue' "title" {
        ifno = "<no title>";
        ifyes = x: "'${x}'";
      };
      author = mprisValue' "artist" {
        ifyes = x: " [${x}]";
      };
    in
    { includeAny }:
    writeShellScript "playerMenu" ''
      origPlayer=${getPlayerFile}
      declare -A menu
      ${lib.optionalString includeAny ''menu["${anyPlayer}"]="${anyPlayer}"''}
      while read -r player; do
        playing="(${pname}/${status}$([[ "$player" == "$origPlayer" ]] && echo "/*")) ${title}${author}"
        menu["$playing"]="$player"
      done < <(${run pkgs.playerctl} --list-all)
      selection="$(
        printf '%s\n' "''${!menu[@]}" \
          | sort \
          | ${menu} -p "plyr>>"
      )"
      [[ -z "$selection" ]] && exit 1
      player="''${menu["$selection"]}"
      ${writePlayerFile "$player"}
    '';
in
{
  wayland.windowManager.sway.config.keybindings = rec {
    XF86AudioPlay = "exec ${shell toggle}";
    XF86AudioPause = XF86AudioPlay;

    "${mod}+equal" = "exec ${playerMenu { includeAny = false; }}";
    "${mod}+plus" = "exec ${playerMenu { includeAny = true; }}";
    "${mod}+semicolon" = XF86AudioPlay;

    "Shift+XF86AudioPlay" = "exec ${shell stop}";
    "${mod}+Shift+semicolon" = "exec ${shell stop}";

    XF86AudioNext = "exec ${ff}";
    "${mod}+bracketright" = XF86AudioNext;

    XF86AudioPrev = "exec ${prev}";
    "${mod}+bracketleft" = XF86AudioPrev;

    "${mod}+Shift+XF86AudioPlay" = "exec ${info}";
    "${mod}+apostrophe" = "exec ${info}";

    XF86MonBrightnessUp = "exec ${run pkgs.bash} -c '${run pkgs.brightnessctl} set 2%+; ${notify "Brightness Raised: ${shell getBrt}%"}'";
    XF86MonBrightnessDown = "exec ${run pkgs.bash} -c '${run pkgs.brightnessctl} set 2%-; ${notify "Brightness Lowered: ${shell getBrt}%"}'";

    XF86AudioMute = "exec pactl set-sink-mute \\@DEFAULT_SINK@ toggle";
    XF86AudioLowerVolume = "exec pactl set-sink-volume \\@DEFAULT_SINK@ -5%";
    XF86AudioRaiseVolume = "exec pactl set-sink-volume \\@DEFAULT_SINK@ +5%";
    XF86AudioMicMute = "exec pactl set-source-mute \\@DEFAULT_SOURCE@ toggle";
  };
}

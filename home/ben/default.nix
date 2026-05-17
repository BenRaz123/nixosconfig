{
  pkgs,
  config,
  lib,
  ...
}:
let
  color = import ./color.nix { inherit pkgs; };

  lightenBy = num: clr: clr |> color.from |> color.lighten num |> toString;
  darkenBy = num: clr: clr |> color.from |> color.darken num |> toString;

  font = config.sysFonts.normal;
  accentColor = "#89DDFF";
  bgcolor = "#0E1019";

  accentBorder = darkenBy 0 accentColor;
  unfocusedText = "#a6accd";
  unfocusedBorder = "#1f2337";

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
in
rec {
  fonts.fontconfig.enable = true;

  imports = [
    ./general/home.nix
    ./modules
  ];

  programs.ghostty = {
    settings.confirm-close-surface = false;
    enable = true;
  };

  programs.bemenu = {
    enable = true;
    settings = {
      center = true;
      fn = "${font.name} 35";
      width-factor = 0.75;
      tf = "#1988ff";
      list = 4;
      ignorecase = true;
      #--c --fn 'DejaVu Sans 35' -W0.75 --tf '#1988FF' -l4 -i"
    };
  };

  services.mako = {
    enable = true;
    settings = {
      # 4 seconds
      default-timeout = "4000";
      font = font.name + " 12";
      layer = "overlay";
      text-color = bgcolor;
      background-color = accentColor;
      border-color = accentBorder;
      max-visible = 10;
    };
  };

  gtk = {
    enable = true;
    font = {
      inherit (font) name;
      size = 11;
      package = font.pkg;
    };
  };

  wayland.windowManager.sway =
    let
      #TODO: Fix this
      BAT = "/org/freedesktop/UPower/devices/battery_macsmc_battery";

      use = cmd: "${pkgs.${cmd}}/bin/${cmd}";
      shell = s: "$(${toString s})";

      mod = "Mod4";
      term = "${use "ghostty"} +new-window -e ${pkgs.writeShellScript "tmux new window" ''
        readonly TMUX=${use "tmux"}
        $TMUX a || $TMUX
      ''}";
      menuRun = "${pkgs.bemenu}/bin/bemenu-run ${settingsToCLI programs.bemenu.settings}";
      menu = "${use "bemenu"} ${settingsToCLI programs.bemenu.settings}";
      desktopMenu = ''${use "j4-dmenu-desktop"} --dmenu="${menu}"'';

      browser = "qutebrowser";
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      bg = import ./bgpic.nix { inherit pkgs; };

      getBrt = pkgs.writeShellScript "get brightness" ''
        echo "scale=0; ($(${use "brightnessctl"} get)*100)/500" | ${use "bc"}
      '';

      getKB = pkgs.writeShellScript "getKB" ''
        swaymsg -t get_inputs \
          | ${use "jq"} '.[].xkb_active_layout_name | select(. != null)' \
          | sort -u \
          | sed 's/"//g'
      '';

      getVol = pkgs.writeShellScript "getVol" ''
        pactl -f json list sinks \
          | ${use "jq"} '.[] 
            | select(.name == "'"$(pactl get-default-sink)"'") 
            | .volume 
            | .[].value_percent' \
          | uniq \
          | tr "\n" ' ' \
          | tr -d '"'
      '';

      getBat = pkgs.writeShellScript "get battery" ''
        readonly RG=${pkgs.ripgrep}/bin/rg
        upower -i ${BAT} \
          | $RG "percentage" \
          | $RG -o '([0-9]+)(?:\.?[0-9]+)' -r '$1'
      '';
      getBatCharging = pkgs.writeShellScript "get charging state" ''
        readonly RG=${pkgs.ripgrep}/bin/rg
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

        ${use "pass"} -c "$sel"
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

      powerMenu = mkMenu "power" {
        Cancel = "exit";
        Lock = "swaylock";
        Reboot = "reboot";
        Suspend = "systemctl suspend";
        "Power Off" = "poweroff";
        Sleep = "systemctl sleep; ${use "swaylock"}";
      };

      notify = msg: ''${use "zenity"} --notification --text "${msg}"'';
    in
    {
      enable = true;
      config = {
        bars =
          let
            preparePangoString =
              s:
              s
              |> builtins.replaceStrings [ "<" ">" ] [ "&lt;" "&gt;" ]
              |> builtins.replaceStrings [ "{{" "}}" ] [ "<" ">" ];
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
              pkgs.writeShellScript "statusbar" ''
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
            percent = s: s + "%";
          in
          [
            {
              extraConfig = "pango_markup enabled";
              statusCommand = mkStatusCommand {
                main = "${shell "whoami"}@${shell <| use "hostname"}";
                audio = shell "pactl get-default-sink";
                kbd = shell getKB;
                vol = shell getVol;
                brt = shell getBrt |> percent;
                bat = " ${
                   shell
                   <| pkgs.writeShellScript "indicator" ''
                     case "${shell getBatCharging}" in
                       charging)
                         echo "<span color='#00ff00'>▴</span>"
                         break
                         ;;
                       discharging) 
                         echo "<span color='#ff0000'>▾</span>"
                         break 
                         ;;
                       pending) 
                         echo "▸"
                         break
                         ;;
                     esac
                   ''
                 }${shell getBat}%";
                time = "${shell "date -R"} ${shell "date -I"}";
              };
              fonts = {
                names = [ font.name ];
                size = 12.0;
              };
              position = "top";
              colors = rec {
                focusedWorkspace = {
                  background = accentColor;
                  border = accentBorder;
                  text = bgcolor;
                };
                inactiveWorkspace = {
                  border = "#1f2337";
                  background = bgcolor;
                  text = "#a6accd";
                };
                background = bgcolor;
                focusedBackground = bgcolor;
                separator = unfocusedBorder;
                statusline = unfocusedText;
                focusedStatusline = statusline;
              };
            }
          ];
        window.commands = [
          {
            command = "title_format '<b>>%title</b> {*%app_id}'";
            criteria.title = ".";
          }
          {
            command = "border pixel 2";
            criteria.app_id = "com.mitchellh.ghostty";
          }
          {
            command = "title_format '[XWAYLAND] <b>%title</b>'";
            criteria.shell = "xwayland";
          }
        ];
        fonts = {
          names = [ font.name ];
          style = "Regular";
          size = 12.0;
        };
        colors =
          let
            default = {
              background = "#285577";
              border = "#4c7899";
              childBorder = "#285577";
              indicator = "#2e9ef4";
              text = "#ffffff";
            };
          in
          {
            focused = default // {
              background = accentColor;
              border = accentColor;
              text = bgcolor;
              childBorder = accentColor;
            };
            unfocused = default // {
              background = bgcolor;
              border = "#1f2337";
              text = "#A6ACCD";
              childBorder = bgcolor;
            };
          };
        defaultWorkspace = "workspace number 1";
        output."*".bg = "${bg} fill";
        bindswitches."lid:on" = {
          reload = true;
          locked = true;
          action = "output eDP-1 disable";
        };
        bindswitches."lid:off" = {
          reload = true;
          locked = true;
          action = "output eDP-1 enable";
        };
        keybindings =
          let
            btHeadphones = "88:92:CC:AC:DD:F0";
          in
          rec {
            "${mod}+Return" = "exec ${term}";
            "${mod}+q" = "kill";
            "${mod}+Shift+Return" = "exec ${browser}";
            "${mod}+d" = "exec ${menuRun}";
            "${mod}+Shift+f" = "exec ${desktopMenu}";

            "${mod}+${left}" = "focus left";
            "${mod}+${down}" = "focus down";
            "${mod}+${up}" = "focus up";
            "${mod}+${right}" = "focus right";

            "${mod}+Shift+${left}" = "move left";
            "${mod}+Shift+${down}" = "move down";
            "${mod}+Shift+${up}" = "move up";
            "${mod}+Shift+${right}" = "move right";

            "${mod}+b" = "exec bluetoothctl connect ${btHeadphones}";
            "${mod}+Shift+b" = "exec bluetoothctl disconnect ${btHeadphones}";

            "${mod}+Shift+c" = "reload";
            "${mod}+Shift+e" =
              "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";

            "${mod}+f" = "fullscreen";

            "${mod}+v" = "splitv";
            "${mod}+Shift+v" = "splith";

            "${mod}+s" = "layout stacking";
            "${mod}+w" = "layout tabbed";
            "${mod}+e" = "toggle split";

            "${mod}+Shift+Space" = "floating toggle";
            "${mod}+Space" = "focus mode_toggle";
            "${mod}+a" = "focus parent";

            # workspace stuff
            "${mod}+1" = "workspace number 1";
            "${mod}+2" = "workspace number 2";
            "${mod}+3" = "workspace number 3";
            "${mod}+4" = "workspace number 4";
            "${mod}+5" = "workspace number 5";
            "${mod}+6" = "workspace number 6";
            "${mod}+7" = "workspace number 7";
            "${mod}+8" = "workspace number 8";
            "${mod}+9" = "workspace number 9";
            "${mod}+0" = "workspace number 10";

            "${mod}+Shift+1" = "move container to workspace number 1";
            "${mod}+Shift+2" = "move container to workspace number 2";
            "${mod}+Shift+3" = "move container to workspace number 3";
            "${mod}+Shift+4" = "move container to workspace number 4";
            "${mod}+Shift+5" = "move container to workspace number 5";
            "${mod}+Shift+6" = "move container to workspace number 6";
            "${mod}+Shift+7" = "move container to workspace number 7";
            "${mod}+Shift+8" = "move container to workspace number 8";
            "${mod}+Shift+9" = "move container to workspace number 9";
            "${mod}+Shift+0" = "move container to workspace number 10";

            "${mod}+r" = "mode 'resize'";

            XF86MonBrightnessUp = "exec ${use "bash"} -c '${use "brightnessctl"} set 2%+; ${notify "Brightness Raised: ${shell getBrt}%"}'";
            XF86MonBrightnessDown = "exec ${use "bash"} -c '${use "brightnessctl"} set 2%-; ${notify "Brightness Lowered: ${shell getBrt}%"}'";

            # audio
            XF86AudioMute = "exec pactl set-sink-mute \\@DEFAULT_SINK@ toggle";
            XF86AudioLowerVolume = "exec pactl set-sink-volume \\@DEFAULT_SINK@ -5%";
            XF86AudioRaiseVolume = "exec pactl set-sink-volume \\@DEFAULT_SINK@ +5%";
            XF86AudioMicMute = "exec pactl set-source-mute \\@DEFAULT_SOURCE@ toggle";

            "${mod}+Shift+s" = "exec ${use "bash"} -c 'systemctl sleep; ${use "swaylock"}'";
            "${mod}+Backslash" = "exec ${use "shotman"} -Cc region";

            "${mod}+c" = "exec makoctl dismiss -a";

            "${mod}+grave" = "exec swaymsg bar mode toggle";

            XF86PowerOff = "exec ${shell powerMenu}";
            "${mod}+Shift+p" = XF86PowerOff;

            "${mod}+p" = "exec ${shell passMenu}";
          };
        keycodebindings =
          let
            startOfNumbers = 9;
            fnKey = "248";
            k = n: "${fnKey}+${builtins.toString (startOfNumbers + n)}";
            f =
              n:
              "exec ${use "bash"} -c '${use "wtype"} -P F${builtins.toString n}; ${notify "F${builtins.toString n}"}'";
            fns =
              from: to:
              let
                attrs = map (x: { ${k x} = f x; }) (range {
                  inherit from to;
                });
              in
              lib.mergeAttrsList attrs;
            range =
              {
                from, # or current
                to,
                accum ? [ ],
              }:
              let
                accum' = accum ++ [ from ];
              in
              if from < to then
                range {
                  inherit to;
                  from = from + 1;
                  accum = accum';
                }
              else
                accum';
          in
          fns 1 12;

        modes.resize = {
          ${left} = "resize shrink width 10px";
          ${right} = "resize grow width 10px";

          ${up} = "resize shrink height 10px";
          ${down} = "resize grow height 10px";
          Return = "mode default";
          Escape = "mode default";
        };
      };
    };
}

{
  colors,
  config,
  keys,
  pkgs,
  scripts,
  utils,
  ...
}:
let
  inherit (colors)
    accentBorder
    accentColor
    bgcolor
    unfocusedBorder
    unfocusedText
    ;

  inherit (keys)
    mod
    ;

  inherit (scripts)
    getBat
    getBatCharging
    getBrt
    getKB
    getVol
    mkStatusCommand
    ;

  inherit (utils)
    percent
    shell
    use
    ;

  font = config.sysFonts.normal;
in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+grave" = "exec swaymsg bar mode toggle";
  };

  wayland.windowManager.sway.config.bars = [
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
}

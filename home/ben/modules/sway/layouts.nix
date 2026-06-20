{ pkgs, scripts, ... }:
let
  inherit (scripts)
    notify
    ;

  notify-layout = pkgs.writeShellApplication {
    name = "notify-layout";
    runtimeInputs = with pkgs; [
      jq
      sway
    ];
    text = ''
      while ev=$(swaymsg -t subscribe '["input"]'); do
        if [[ "$(echo "$ev" | jq '.change == "xkb_layout"')" == "true" ]]; then
          layout="$(echo "$ev" | jq ".input.xkb_active_layout_name")"
          echo "New Layout: $layout"
          ${notify "KB: $layout"}
        fi
      done
    '';
  };
in
{
  systemd.user.services.notify-layout = {
    Unit.Description = "notify of changes to the keyboard layout";
    Unit.PartOf = "sway-session.target";
    Service.ExecStart = "${notify-layout}/bin/notify-layout";
    Install.WantedBy = [ "sway-session.target" ];
  };

  wayland.windowManager.sway.config.input."type:keyboard" = {
    xkb_layout = "us,il";
    xkb_options = "grp:caps_toggle";
  };
}

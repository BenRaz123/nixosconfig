{ pkgs, ... }:
let
  colorctl = pkgs.writeShellApplication rec {
    name = "colorctl";
    runtimeInputs = with pkgs; [
      coreutils
      glib
    ];
    text = /* bash */ ''
      readonly STORE_PATH="''${XDG_DATA_HOME:-"$HOME/.local/share"}/${name}/SELECTED_THEME"      

      info() {
        echo "[INFO] $1" >&2
      }

      dark() {
        info "setting dark theme"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
        echo "dark" >"$STORE_PATH"
      }

      light() {
        info "setting light theme"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-light"
        echo "light" >"$STORE_PATH"
      }

      toggle() {
        info "toggling theme"
        case "$(cat "$STORE_PATH")" in 
          dark) light ;;
          light) dark ;;
        esac
        cat "$STORE_PATH"
      }

      if [ ! -s "$STORE_PATH" ]; then 
        info "$STORE_PATH is unset. setting it to 'light'"
        mkdir -p "$(dirname "$STORE_PATH")" || true
        echo "light" >"$STORE_PATH"
      fi
      if [[ -z "$1" ]]; then
          exit 1
      fi

      case "$1" in
        dark) dark ;;
        light) light ;;
        toggle) toggle ;;
      esac
    '';
  };

in
{
  home.packages = [ colorctl ];
  # this code is only running on nixos so its fine.
  systemd.user = {
    enable = true;

    services."colorctl@" = {
      Unit.Description = "Set color scheme to %I";
      Service.Type = "oneshot";
      Service.ExecStart = "${colorctl}/bin/colorctl %i";
    };

    timers."colorctl@light" = {
      Timer.OnCalendar = "*-*-* 8:00:00";
      Timer.Persistent = true;
      Install.WantedBy = [ "timers.target" ];
    };

    timers."colorctl@dark" = {
      Timer.OnCalendar = "*-*-* 19:00:00";
      Timer.Persistent = true;
      Install.WantedBy = [ "timers.target" ];
    };
  };
}

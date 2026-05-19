{ pkgs, ... }:
{
  systemd.services.bt-a2dp-fix = {
    description = "Bluetooth A2DP stutter fix for Apple Silicon";

    after = [ "bluetooth.target" ];
    wants = [ "bluetooth.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      bluez
      expect # provides unbuffer
      gnugrep
      bash
      coreutils
    ];

    script = ''
      # Bluetooth A2DP stutter fix for Apple Silicon (BCM4377/4378/4387)
      # https://github.com/bluez/bluez/issues/722
      unbuffer bluetoothctl --monitor | while read -r line; do
          if [[ "$line" =~ Device.*([0-9A-F:]{17}).*Connected:\ yes ]]; then
              mac="''${BASH_REMATCH[1]}"
              sleep 2

              bluetoothctl info "$mac" | grep -q "Audio Sink" || continue

              handle=$(hcitool con | grep -i "$mac" | grep -oP 'handle \K[0-9]+')

              [[ -n "$handle" ]] && \
                hcitool cmd 0x3f 0x57 "$(printf 0x%02X "$handle")" 0x00 0x01
          fi
      done
    '';

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
    };
  };
}

{
  pkgs,
  lib ? pkgs.lib,
  config,
  ...
}:
let
  cfg = config.laptopBattery;
  setBatCap = pkgs.writeShellApplication {
    name = "set-battery-capacity";
    runtimeInputs = with pkgs; [ coreutils ];
    runtimeEnv.BAT = "/sys/class/power_supply/${cfg.batteryName}/charge_control_end_threshold";
    text = ''
      case "$1" in
        80|100) ;;
        *)
          echo "[WARN] dont set different from 80 or 100" 
          ;;
      esac

      echo "$1" >"$BAT"
    '';
  };
in
{
  options = {
    laptopBattery = {
      enable = lib.mkEnableOption "enable utilities for the laptop battery";
      batteryName = lib.mkOption {
        description = "the name to use for this battery (goes under /sys/class/power_supply/<NAME>)";
        type = lib.types.str;
        example = "macsmc-battery";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;
      };
    };

    services.auto-cpufreq.enable = false;
    services.power-profiles-daemon.enable = false;

    systemd.services."set-battery-capacity@" = {
      description = "set battery capacity to %I%%";
      script = "${lib.run setBatCap} %i";
    };

    systemd.timers = {
      "set-battery-capacity@80" = {
        description = "Set battery capacity down after the morning";
        timerConfig.OnCalendar = "*-*-* 11:00:00";
        wantedBy = ["timers.target"];
      };
      "set-battery-capacity@100" = {
        description = "Set battery capacity up before the morning during weekdays";
        timerConfig.OnCalendar = "Mon..Fri *-*-* 03:00:00";
        wantedBy = ["timers.target"];
      };
    };
  };
}

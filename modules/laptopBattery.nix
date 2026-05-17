{
  pkgs,
  lib ? pkgs.lib,
  config,
  ...
}:
let
  cfg = config.laptopBattery;
in
{
  options = {
    laptopBattery = {
      enable = lib.mkEnableOption "enable utilities for the laptop battery";
      highThreshold.calendar = lib.mkOption {
        description = "systemd timer time that the high charging threshold should be activated";
        type = lib.types.str;
        default = "Mon..Fri 06:30";
      };
      lowThreshold.calendar = lib.mkOption {
        description = "systemd timer time that the low charging threshold should be activated";
        type = lib.types.str;
        default = "Mon..Fri 10:00";
      };
      enableCpuGovernors = lib.mkOption {
        type = lib.types.bool;
        description = "whether we should use cpu frequency governors";
        default = true;
      };
      #TODO: add option for lowThreshold.percentage
      batteryName = lib.mkOption {
        description = "the name to use for this battery (goes under /sys/class/power_supply/<NAME>)";
        type = lib.types.str;
        example = "macsmc-battery";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp.enable = false;
    services.power-profiles-daemon.enable = false;
    services.auto-cpufreq =
      if cfg.enableCpuGovernors then
        {
          enable = true;
          settings = {
            battery = {
              governor = "powersave";
              turbo = "never";
            };
            charger = {
              governor = "performance";
              turbo = "auto";
            };
          };
        }
      else
        { enable = false; };

    systemd.services.battery-threshold-100 = {
      description = "Set battery threshold to 100%";
      serviceConfig.Type = "oneshot";
      script = ''
        echo 100 > /sys/class/power_supply/${cfg.batteryName}/charge_control_end_threshold
      '';
    };

    systemd.timers.battery-threshold-100 = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.lowThreshold.calendar;
        Persistent = true;
      };
    };

    systemd.services.battery-threshold-80 = {
      description = "Set battery threshold to 80%";
      serviceConfig.Type = "oneshot";
      script = ''
        echo 80 > /sys/class/power_supply/${cfg.batteryName}/charge_control_end_threshold
      '';
    };

    systemd.timers.battery-threshold-80 = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.highThreshold.calendar;
        Persistent = true;
      };
    };
  };
}

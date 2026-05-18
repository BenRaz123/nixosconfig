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
  };
}

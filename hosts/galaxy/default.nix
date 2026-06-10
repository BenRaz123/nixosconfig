# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  pkgs,
  ...
}:

{
  imports = [
    ./modules
    ../../modules/printing/extraOpts.nix
  ];

  laptopBattery = {
    enable = true;
    batteryName = "macsmc-battery";
  };

  hardware.asahi.peripheralFirmwareDirectory = ./asahi-fw;

  system.stateVersion = "25.11"; # Did you read the comment?

}

{ pkgs, ... }:
{
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    disabledDefaultBackends = [ "epsonds" ];
  };

  networking.firewall.allowedTCPPorts = [
    139
    445
  ];
}

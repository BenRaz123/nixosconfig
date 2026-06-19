{ pkgs, ... }:
{
  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    disabledDefaultBackends = [ "epsonds" ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/scans 0770 root scans -"
  ];

  services.samba = {
    enable = true;

    settings = {
      scans = {
        path = "/srv/scans";
        browseable = "yes";
        writable = "yes";
        "guest ok" = "no";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  networking.firewall.allowedTCPPorts = [
    139
    445
  ];
}

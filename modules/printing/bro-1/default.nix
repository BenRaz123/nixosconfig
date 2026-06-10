{ lib, pkgs, ... }:
{
  services.printing.drivers = [
    (pkgs.linkFarm "drivers" [
      {
        name = "share/cups/model/bro-1.ppd";
        path = ./bro-1.ppd;
      }
    ])
  ];

  hardware.printers.ensurePrinters = [
    {
      name = "bro-1";
      deviceUri = "dnssd://Brother%20HL-L2370DW%20series._ipp._tcp.local/?uuid=e3248000-80ce-11db-8000-b42200bacd81";
      model = "bro-1.ppd";
    }
  ];

  hardware.printers.ensureClasses."bw-laser" = {
    printers = [ "bro-1" ];
  };
}

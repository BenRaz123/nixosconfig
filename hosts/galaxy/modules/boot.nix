{ pkgs, ... }:
{
  boot = {
    kernelPatches = [
      {
        name = "apple-use-pmp";
        patch = "${pkgs.writeText "pmp.patch" ''
          diff --git a/arch/arm64/boot/dts/apple/t6000-j314s.dts b/arch/arm64/boot/dts/apple/t6000-j314s.dts
          index afa866684..86f7f3d38 100644
          --- a/arch/arm64/boot/dts/apple/t6000-j314s.dts
          +++ b/arch/arm64/boot/dts/apple/t6000-j314s.dts
          @@ -9,6 +9,8 @@
           
           /dts-v1/;
           
          +#define APPLE_USE_PMP
          +
           #include "t6000.dtsi"
           #include "t600x-j314-j316.dtsi"

        ''}";
      }
    ];

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;
  };
}

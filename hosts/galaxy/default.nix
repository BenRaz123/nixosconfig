# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  pkgs,
  ...
}:

{
  laptopBattery = {
    enable = true;
    batteryName = "macsmc-battery";
  };

  #NOTE: this part was not included in the actual build that failed to produce the boot object
  hardware.asahi.peripheralFirmwareDirectory = ./asahi-fw;

  # Use the systemd-boot EFI boot loader.
  #boot.kernel.sysctl."vm.mmap_rnd_bits" = 31;
  boot.loader.systemd-boot.enable = true;
  #boot.loader.grub = {
  #  fontSize = 36;
  #  font = "${pkgs.nerd-fonts.cousine}/share/fonts/truetype/NerdFonts/Cousine/CousineNerdFontMono-Regular.ttf";
  #  backgroundColor = "#151519";
  #  enable = true;
  #  efiSupport = true;
  #  device = "nodev";
  # efiInstallAsRemovable = true;
  # };
  # for apple silicon
  boot.loader.efi.canTouchEfiVariables = false;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  services = {
    gnome.gnome-keyring.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    openssh.enable = true;
  };

  programs = {
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  environment.systemPackages = with pkgs; [
    zathura
    chromium
    gnupg
    coreutils
    git
    home-manager
    mako
    neovim
    sway
    wget
    wl-clipboard
  ];

  system.stateVersion = "25.11"; # Did you read the comment?

}

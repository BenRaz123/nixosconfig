{
  pkgs,
  hostname,
  ...
}@args:
let
  inherit (pkgs) lib;
in
{
  # it doesnt work
  #services.automatic-timezoned.enable = true;
  time.timeZone = lib.mkDefault "America/New_York";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "pipe-operators"
  ];

  # we *should* be using the hostname given to use by `mkSys` but if for some reason not, it is overridable
  networking.hostName = lib.mkDefault hostname;

  users.users.ben = rec {
    name = "ben";
    home = "/home/${name}";
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = lib.mkDefault true;
    };
    logind.settings.Login.HandlePowerKey = lib.mkDefault "ignore";
    logind.settings.Login.HandlePowerKeyLongPress = lib.mkDefault "poweroff";
    envfs.enable = true;
    printing.enable = true;
  };

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
    (mpv.override { scripts = [ mpvScripts.mpris ]; })
  ];
}

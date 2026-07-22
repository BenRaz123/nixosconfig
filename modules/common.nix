{
  pkgs,
  hostname,
  ...
}@args:
let
  inherit (pkgs) lib;
in
{
  security.wrappers.wshowkeys = {
    source = lib.getExe pkgs.wshowkeys;
    owner = "root";
    group = "root";
    setuid = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/c/nixos"; # sets NH_OS_FLAKE variable for you
  };

  symlinks = [
    {
      source = "/home/ben/Music";
      destination = "/m";
    }
    {
      source = "/home/ben/work";
      destination = "/w";
    }
    {
      source = "/home/ben/.config";
      destination = "/c";
    }
  ];

  xdg.portal.config.sway.default = lib.mkForce "wlr";
  xdg.portal.config.sway."org.freedesktop.portal.OpenURI.OpenURI" = "wlr";

  virtualisation.docker = {
    # Consider disabling the system wide Docker daemon
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
      # Optionally customize rootless Docker daemon settings
      daemon.settings = {
        dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        registry-mirrors = [ "https://mirror.gcr.io" ];
      };
    };
  };

  services.kmscon = {
    enable = true;
    extraOptions = "--no-mouse";
  };

  imports = [
    ./printing
  ];

  hardware.bluetooth = {
    enable = true;
    input = {
      General = {
        UserspaceHID = true;
      };
    };
  };

  # it doesnt work
  #services.automatic-timezoned.enable = true;
  time.timeZone = lib.mkDefault "America/New_York";
  environment.sessionVariables.TZDIR = "/etc/zoneinfo";

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
      "scanner"
      "lp"
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
    ripgrep
    prismlauncher
    fractal
    zathura
    chromium
    gnupg
    coreutils
    git
    home-manager
    mako
    #neovim
    sway
    wget
    wl-clipboard
    (mpv.override { scripts = [ mpvScripts.mpris ]; })
  ];
}

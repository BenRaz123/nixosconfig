{
  config, pkgs,
  lib,
  osConfig ? null,
  inputs ? null,
  ...
}:
let
  nixvim =
    if (inputs ? nixvim) then
      inputs.nixvim
    else
      import (fetchGit {
        url = "https://github.com/nix-community/nixvim";
        ref = if config.settings.VERSION != "unstable" then "nixos-${config.settings.VERSION}" else "main";
      });
in
{
  imports = [
    nixvim.homeModules.nixvim
    ./settings
    ./programs
  ];

  home.username = lib.mkDefault config.settings.USER;
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";

  home.stateVersion = config.settings.VERSION;

  home.packages =
    with pkgs;
    [
      fish
      gnupg
      maestral
      nixfmt
      qutebrowser
      tmux
    ]
    ++ [ config.programs.password-store.package ];

  home.sessionVariables =
    let
      getChain =
        obj: props:
        if props == [ ] then
          obj
        else
          let
            prop = builtins.head props;
            rest = builtins.tail props;
            obj' = obj.${prop} or null;
          in
          if obj' == null then null else getChain obj' rest;

      osTZDIR = getChain osConfig [
        "environment"
        "sessionVariables"
        "TZDIR"
      ];

      nvim = lib.getExe config.programs.nixvim.build.package;
    in
    rec {
      inherit (config.settings)
        TZ
        ;
      MANPAGER = "${nvim} +Man!";
      EDITOR = lib.mkForce nvim;
      VISUAL = EDITOR;
      TZDIR = if osTZDIR != null then osTZDIR else "/usr/share/zoneinfo";
      X = 5;
    };
}

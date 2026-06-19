{ pkgs, ... }:
{
  programs.nixvim.files."ftplugin/nix.lua".localOpts = {
    expandtab = true;
    shiftwidth = 2;
    tabstop = 2;
    formatprg = "${pkgs.nixfmt}/bin/nixfmt";
  };
}

{ config, ... }:
let
  inherit (config.settings)
    TAB_WIDTH
    ;
in
{
  programs.nixvim = {
    clipboard.register = "unnamedplus";
    opts = {
      tabstop = TAB_WIDTH;
      shiftwidth = TAB_WIDTH;
      number = true;
      relativenumber = true;
      signcolumn = "yes";
    };
    globals = {
      mapleader = " ";
    };
  };
}

{
  imports = [
    ./autocmds.nix
    ./extra_plugins.nix
    ./keymaps.nix
    ./lsp.nix
    ./opts.nix
    ./plugins.nix
    ./vimlib.nix

    ./ft
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    extraConfigLua = builtins.readFile ./extraConfig.lua;
  };
}

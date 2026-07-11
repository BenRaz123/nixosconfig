{
  config,
  hostname ? null,
  ...
}:
{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      cssls.enable = true;
      phpactor.enable = true;
      html.enable = true;
      ts_ls.enable = true;
      clangd.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };
      nixd = {
        enable = true;
        config = {
          filetypes = [
            "nix"
          ];
          root_markers = [
            ".git"
            "flake.nix"
          ];
          settings.nixd = {
            nixpkgs.expr = "import <nixpkgs> {}";
            formatting.command = "nixfmt";
            options.nixos.expr = "(builtins.getFlake (toString ./.)).nixosConfigurations.${hostname}.options";
            options.home_manager.expr = ''(builtins.getFlake (toString ./.)).homeConfigurations."${config.username}".options'';
          };
        };
      };
      pyright.enable = true;
      lua_ls.enable = true;
    };
  };
}

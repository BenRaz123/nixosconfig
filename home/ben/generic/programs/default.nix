{
  imports = [
    ./gh.nix
    ./git.nix
    ./bash.nix
    ./tmux.nix

    ./nixvim
  ];
  programs.home-manager.enable = true;
}

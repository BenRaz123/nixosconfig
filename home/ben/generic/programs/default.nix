{
  imports = [
    ./gh.nix
    ./git.nix
    ./bash.nix
    ./tmux.nix
    ./yt-dlp.nix

    ./nixvim
  ];
  programs.home-manager.enable = true;
}

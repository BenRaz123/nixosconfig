{ config, ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      gm = "mutt -F ~/.mutt/school.muttrc";
      Gm = "mutt -F ~/.mutt/personal.muttrc";
    };
    sessionVariables = {
      COLOR_START = ''\e[92m'';
      COLOR_END = ''\e[0m'';
      PS1 = ''[\u@\h $COLOR_START\w$COLOR_END]\$ '';
    };
    initExtra = ''
      #."$HOME/.nix-profile/etc/profile.d/nix.sh"
      export TZ=${config.settings.TZ}
      set -o vi
    '';
  };
}

{ pkgs, ... }:
{
  shellScripts = {
    open = {
      path = [ pkgs.xdg-utils ];
      text = /* sh */ ''
        xdg-open "$1"
      '';
    };
  };
}

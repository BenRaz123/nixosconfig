{
  config,
  pkgs,
  ...
}:
let
  mkGit = text: {
    inherit text;
    path = [ pkgs.git ];
  };
in
{
  shellScripts = {
    ga = mkGit /* sh */ ''
      git add "$@"
    '';

    gs = mkGit /* sh */ ''
      git status --short
    '';

    gc = {
      env = {
        inherit (config.home.sessionVariables)
          VISUAL
          ;
      };
      path = [ pkgs.git ];
      text = /* sh */ ''
        if [ -s "$2" ]; then
          git commit -s -m "$2"
        else
          git commit -s
        fi
      '';
    };

    gac = {
      env = {
        inherit (config.home.sessionVariables)
          VISUAL
          ;
      };
      path = [ pkgs.git ];
      text = /* sh */ ''
        git add "$1"
        if [ -s "$2" ]; then
          git commit -s -m "$2"
        else
          git commit -s
        fi
      '';
    };
  };
}

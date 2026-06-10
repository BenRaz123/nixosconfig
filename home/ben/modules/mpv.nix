{
  pkgs,
  ...
}:
{
  programs.mpv = {
    enable = true;
    config = {
      audio-display = "no";
    };
    scripts = with pkgs; [
      mpvScripts.mpris
      mpvScripts.builtins.autoload
      mpvScripts.modernx
    ];
  };
}

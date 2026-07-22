{ inputs, system, ... }:
let
  inherit (import inputs.nixpkgs-yt-dlp { inherit system; })
    yt-dlp
    ;
in
{
  home.packages = [ yt-dlp ];
  shellScripts = {
    dl-audio = {
      path = [ yt-dlp ];
      text = /* sh */ ''
        yt-dlp \
          -x                       \
          --audio-format mp3       \
          --embed-thumbnail        \
          --convert-thumbnails jpg \
          --embed-metadata         \
          --add-metadata           \
          "$1"
      '';
    };
    dl-playlist = {
      path = [ yt-dlp ];
      env.OUT_FORMAT = "%(playlist_index)02d - %(title)s.%(ext)s";
      text = /* sh */ ''
        yt-dlp \
          -x                       \
          --audio-format mp3       \
          --embed-thumbnail        \
          --convert-thumbnails jpg \
          --embed-metadata         \
          --add-metadata           \
          -o "$OUTPUT_FORMAT"      \
          "$1"
      '';
    };
  };
}

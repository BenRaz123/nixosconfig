{
  config,
  lib,
  nixosConfig ? null,
  ...
}:
let
  opt = c: x: if c then x else null;
  mkFeatures =
    features:
    let
      lines = lib.mapAttrsToList (
        tpat: tfeatures:
        lib.optionalString (tfeatures != null && tpat != null) (
          let
            featuresList = lib.concatStringsSep ":" tfeatures;
          in
          ''
            set -as terminal-features ",${tpat}:${featuresList}"
          ''
        )
      ) features;
    in
    lib.concatStringsSep "\n" lines;
  fullFeatures = [
    "256"
    "RGB"
  ];
  termFeatures = mkFeatures {
    linux = opt (nixosConfig != null && nixosConfig.services.kmscon.enable) fullFeatures;
    "xterm*" = fullFeatures;
    "screen*" = fullFeatures;
  };
in
{
  programs.tmux = {
    shell = config.settings.shell;
    enable = true;
    keyMode = "vi";
    shortcut = "a";
    extraConfig = ''
      bind Enter popup
      bind T set -g status
      set -g status-style fg=white,bg=black
      bind r source-file ~/.config/tmux/tmux.conf \; display "<<#[bold]Reload#[nobold]>>"
      set -g status-left-length 0
      set -g status-left ""
      set -g window-status-format "[#I]"
      set -g window-status-current-format "#[bold]#[fg=blue][#I]"
      set -g status-right "#(date -I) (#(fish -c get_batt)%) #[fg=green,bold]<#S>#[nobold,fg=white]"
      set -g status-position top

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
    ''
    + termFeatures;
  };
}

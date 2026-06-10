{ pkgs, ... }:
let
  serviceName = "sync-music-folder-iphone";
  log = msg: ''
    {
      echo "LOG: ${msg}"
      ${pkgs.zenity}/bin/zenity --notification --text "Music Sync\n${msg}"
    } || true
  '';
  sync = ''
    ${log "Syncing files..."}
    if rsync -rt --delete --no-perms --no-owner --no-group --inplace "${music}"/ "${mount}"/; then
      ${log "Syncing files succeeded"}
    else
      ${log "Syncing files failed"}
      exit 1
    fi
  '';

  app = "org.videolan.vlc-ios";
  mount = "$HOME/iPhoneVLCMedia";
  music = "$HOME/Music";
in
{
  services.usbmuxd.enable = true;

  #  systemd.user.services."stop-${serviceName}" = {
  #    description = "Kill Music Sync Service";
  #    serviceConfig.Type = "oneshot";
  #    unitConfig.Requires = "${serviceName}.service";
  #    script = ''
  #      ${log "Removing iPhone Media Folder"}
  #      fusermount -u "${mount}" 2>/dev/null || true
  #      systemd --user stop ${serviceName}.service
  #    '';
  #  };

  systemd.user.services.${serviceName} = {
    description = "Sync music to VLC on iPhone";

    serviceConfig = {
      Restart = "no";
    };

    path = with pkgs; [
      fuse
      ifuse
      inotify-tools
      libimobiledevice
      rsync
    ];

    script = ''
      ${log "iPhone has been mounted"}

      mkdir -p "${mount}"
      mkdir -p "${music}"

      if ! ifuse --list-apps | grep -q "${app}"; then
        ${log ''
          VLC is not installed on this iPhone!
          Unmounting...
        ''}
        exit 0
      fi

      ifuse --documents "${app}" "${mount}"

      ${sync}

      {
        while inotifywait -r -e modify,create,delete,move "${music}" >/dev/null 2>&1 || true; 
        do
          sleep 1
          ${sync}
        done
      } &

      child="$!"

      while ideviceinfo >/dev/null 2>&1; do
        sleep 1;
      done

      kill "$child"
      ${log "Removing iPhone Media Folder"}
      fusermount -u "${mount}" 2>/dev/null || true
      exit;
    '';
  };

  services.udev.extraRules = ''
    ACTION=="add", ATTRS{product}=="iPhone", SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="${serviceName}.service"
  '';
}

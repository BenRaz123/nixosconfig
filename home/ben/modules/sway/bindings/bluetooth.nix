{
  keys,
  scripts,
  ...
}:
let
  inherit (keys)
    mod
    ;

  inherit (scripts)
    doCmd
    notify
    ;

  btHeadphones = "88:92:CC:AC:DD:F0";
in
{
  wayland.windowManager.sway.config.keybindings = {
    "${mod}+b" = "exec ${
      doCmd "bluetoothctl connect ${btHeadphones}" {
        ifSuccess = notify "Connected to Bluetooth Headphones";
        ifFail = notify "Failed to Connect to Bluetooth Headphones";
      }
    }";

    "${mod}+Shift+b" = "exec ${
      doCmd "bluetoothctl disconnect ${btHeadphones}" {
        ifSuccess = notify "Disconnected from Bluetooth Headphones";
        ifFail = notify "Failed to Disconnect from Bluetooth Headphones";
      }
    }";
  };
}

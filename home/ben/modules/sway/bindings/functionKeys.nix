{
  lib,
  pkgs,
  scripts,
  utils,
  ...
}:
let
  inherit (lib)
    run
    ;

  inherit (scripts)
    notify
    ;

  startOfNumbers = 9;

  fnKey = "248";

  k = n: "${fnKey}+${toString (startOfNumbers + n)}";

  f = n: "exec ${run pkgs.bash} -c '${run pkgs.wtype} -P F${toString n}; ${notify "F${toString n}"}'";

  fns =
    range:
    let
      attrs = map (x: { ${k x} = f x; }) range;
    in
    lib.mergeAttrsList attrs;
in
{
  wayland.windowManager.sway.config.keycodebindings = fns [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
    11
    12
  ];
}

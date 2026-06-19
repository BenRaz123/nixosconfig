{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  ...
}:
let
  mkPlannerCapture' = keybind: name: short: deadline: {
    ${keybind} = {
      description = name;
      template = "* TODO %? :${lib.toLower short}:\n  DEADLINE: ${deadline}";
    };
  };
  mkPlannerCapture =
    keybind: name: short:
    mkPlannerCapture' keybind name short ''
      %(
        local t = os.time() + 24*60*60
        local firstPart = os.date("<%Y-%m-%d ", t)
        -- We are doing this becuase the %a does not work for whatever reason
        local secondPart = os.date("%A", t):sub(1,3) 
        return firstPart .. secondPart .. " 8:30>"
      )
    '';
in
{
  config.settings = {
    shell = "${pkgs.bash}/bin/bash";
    org = {
      enable = true;
      useDropbox = true;
      plannerCaptures = lib.mergeAttrsList [
        (mkPlannerCapture "h" "History" "hist")
        (mkPlannerCapture "s" "Science" "sci")
        (mkPlannerCapture "f" "Focus" "foc")
        (mkPlannerCapture' "u" "FDU" "fdu" "%<<%Y-%m-%d %a 23:59>>")
        (mkPlannerCapture "m" "Math" "math")
        (mkPlannerCapture "l" "Literature" "lit")
        (mkPlannerCapture "M" "Misc" "misc")
      ];
    };

    VERSION = "25.11";

    USER = "ben";

    TAB_WIDTH = 4;
  };
}

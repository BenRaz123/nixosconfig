{ config, ... }:
{
  programs.bemenu = {
    enable = true;
    settings = {
      center = true;
      fn = "${config.sysFonts.normal.name} 35";
      width-factor = 0.75;
      tf = "#1988ff";
      list = 4;
      ignorecase = true;
    };
  };
}

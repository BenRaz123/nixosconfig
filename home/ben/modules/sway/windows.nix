{
  wayland.windowManager.sway.config.window.commands = [
    {
      command = "title_format '<b>>%title</b> {*%app_id}'";
      criteria.title = ".";
    }
    {
      command = "border pixel 2";
      criteria.app_id = "com.mitchellh.ghostty";
    }
    {
      command = "title_format '[XWAYLAND] <b>%title</b>'";
      criteria.shell = "xwayland";
    }
  ];
}

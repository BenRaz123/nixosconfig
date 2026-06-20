{
  _module.args.vimlib = {
    mkAutoCmd = event: pattern: command: { inherit event pattern command; };
    mkAutoCmdCb = event: pattern: cb: {
      inherit event pattern;
      callback = {
        __raw = "function (args)\n${cb}\nend";
      };
    };
    mkKeyMap = key: action: mode: { inherit key action mode; };
  };
}

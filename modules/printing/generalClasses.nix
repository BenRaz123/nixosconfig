{
  hardware.printers.ensureClasses = {
    # combined categories
    bw-laser = {
      description = "Black and white laser printer";
    };
    bw-inkjet = {
      description = "Black and white inkjet printer";
    };
    color-laser = {
      description = "Color laser printer";
    };
    color-inkjet = {
      description = "Color inkjet printer";
    };

    # singular categories
    bw = {
      description = "Black and white printer";
      classes = [
        "bw-laser"
        "bw-inkjet"
      ];
    };
    color = {
      description = "Color printer";
      classes = [
        "color-laser"
        "color-inkjet"
      ];
    };
    laser = {
      description = "Laser printer";
      classes = [
        "bw-laser"
        "color-laser"
      ];
    };
    inkjet = {
      description = "Inkjet printer";
      classes = [
        "bw-inkjet"
        "color-inkjet"
      ];
    };
  };
}

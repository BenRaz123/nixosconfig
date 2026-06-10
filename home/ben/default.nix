{
  inputs,
  ...
}:
{
  imports = [
    ./modules

    inputs.main-hm-configuration.homeModules.ben
  ];
}

{ lib, ... }:
{
  boot.kernelPatches = map (x: {
    name = baseNameOf x;
    patch = x;
  }) (lib.filesystem.listFilesRecursive (./patches));
}

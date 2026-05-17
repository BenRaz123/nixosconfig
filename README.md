# NixOS Configuration

![screenshot](./assets/image.png)

## About

This configuration includes the following:
- Common NixOS configuration
- Host specific configuration (`/hosts/$HOST`)
- NixOS-specific home-manager modules

It is structured as a flake.

## Adding hosts

1) Copy over `/etc/nixos/${configuration,hardware-configuration}.nix` into `/hosts/$HOST/${default,hardware-configuration.nix}` respectively.
2) Remove redundancies from the default.nix file
3) Add `mkSys` with the relevant information into `outputs.nixosConfigurations`
4) Run:
    ```bash
    [you@host]# nixos-rebuild \
        --extra-experimental-features "pipe-operators" \
        switch \
        --flake path:.#$host
    ```
    (or you can use `test` if you don't want to commit the new configuration to the boot screen)

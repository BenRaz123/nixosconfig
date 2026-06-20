{
  pkgs,
  lib,
  ...
}:
let

  versionFromRev = rev: if builtins.stringLength rev == 40 then builtins.substring 0 7 rev else rev;

  fromGithub =
    {
      owner,
      repo,
      rev,
      sha256 ? lib.fakeHash,
      version ? versionFromRev (rev),
    }:
    pkgs.vimUtils.buildVimPlugin {
      inherit version;
      pname = repo;
      src = pkgs.fetchFromGitHub {
        inherit
          owner
          repo
          rev
          sha256
          ;
      };
      doCheck = false;
    };
in
{
  programs.nixvim.extraPlugins = [
    (fromGithub {
      owner = "lewis6991";
      repo = "gitsigns.nvim";
      rev = "42d6aed4e94e0f0bbced16bbdcc42f57673bd75e";
      sha256 = "sha256-L89x9n2OKCyUuWaNXPkuNGBEU9EBX+9zRlzS1Kfw428=";
      version = "v2.0.0";
    })

    (fromGithub {
      owner = "rickhowe";
      repo = "wrapwidth";
      rev = "a766191a1cd24ebb95d669ebd4a440c50d7f4422";
      sha256 = "sha256-4UJd+86a6Yk7+cixsCKbuCVqtCxlG0vPQWbIuc9ntBg=";
    })
  ];
}

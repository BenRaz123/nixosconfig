{ vimlib, ... }:

let
  inherit (vimlib)
    mkKeyMap
    ;
in
{
  programs.nixvim.keymaps = [
    (mkKeyMap ">" ">gv" "v")
    (mkKeyMap "<" "<gv" "v")
    (mkKeyMap "<C-A>" "ggVGG" [
      "i"
      "n"
    ])
    (mkKeyMap "<C-c>" "<cmd>noh<cr>" [
      "i"
      "n"
    ])
    (mkKeyMap "<leader>c" "<cmd>clo<cr>" "n")
    (mkKeyMap "<leader>b" "<cmd>bd!<cr>" "n")
    (mkKeyMap "e" "<cmd>Ex<cr>" "n")
  ];
}

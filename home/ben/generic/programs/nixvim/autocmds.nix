{ vimlib, ... }:
let
  inherit (vimlib)
    mkAutoCmd
    mkAutoCmdCb
    ;
in
{
  programs.nixvim.autocmd = [
    (mkAutoCmdCb "BufWritePost" "*" ''
      local client = vim.lsp.get_clients({bufnr=args.buf})[1]
      if not client then
        return
      end
      if client.supports_method(client, "textDocument/formatting") then
        vim.lsp.buf.format()
      end

      local fp = vim.bo.formatprg

      if fp ~= "" then
        vim.cmd("%!" .. fp)
      end
    '')
    (mkAutoCmdCb [ "BufRead" "BufNewFile" ] "*.lua" ''
      vim.keymap.set("ia", "!=", "~=", {buffer=args.buf})
      vim.keymap.set("ia", ">f", "function", {buffer=args.buf})
    '')
    (mkAutoCmd "BufRead" "*.muttrc" "set ft=muttrc")
    (mkAutoCmd "FileType" "mail" "Wrapwidth 80 | set spell tw=0")
    (mkAutoCmd "BufEnter" "*nix" "set tabstop=2 shiftwidth=2 expandtab")
  ];
}

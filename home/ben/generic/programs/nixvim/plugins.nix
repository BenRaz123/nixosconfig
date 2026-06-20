{
  config,
  ...
}:
let
  inherit (config.settings)
    org
    ;
in
{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      highlight.enable = true;
    };
    orgmode =
      if org.enable then
        {
          enable = true;
          settings =
            let
              prefix = if org.useDropbox then "~/Dropbox/Apps/MobileOrg" else "~/orgfiles";
            in
            {
              org_agenda_files = "${prefix}/**/*";
              org_default_notes_file = "${prefix}/refile.org";
              org_capture_templates.p =
                if org.plannerCaptures != { } then
                  {
                    description = "Planner";
                    subtemplates = builtins.mapAttrs (
                      _k: v: v // { target = "${prefix}/planner.org"; }
                    ) org.plannerCaptures;
                  }
                else
                  { };
            };
        }
      else
        { };
    cmp = {
      enable = true;
      #autoload = true;
      settings = {
        enableAutoSources = true;
        snippet.expand = ''
          function(args)
          			vim.snippet.expand(args.body)
          		end'';
        mapping = {
          "<CR>" = "cmp.mapping.confirm({ select = false })";
          "<Down>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
          "<Up>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
        };
        sources = [
          { name = "nvim_lsp"; }
          #{ name = "path"; }
          #{ name = "buffer"; }
        ];
        window =
          let
            opt = {
              border = [
                "┌"
                "─"
                "┐"
                "│"
                "┘"
                "─"
                "└"
                "│"
              ];
              winhighlight = "Normal:CmpNormal,FloatBorder:CmpSecondary";
            };
          in
          {
            completion = opt;
            documentation = opt;
          };
      };
    };
  };
}

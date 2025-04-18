{
  pkgs,
  ...
}: let
  # inherit (config) colorscheme;
  # hash = builtins.hashString "md5" (builtins.toJSON colorscheme.colors);
in {
  programs.helix = {
    enable = true;
    settings = {
      # theme = "nix-${hash}";
      theme = "catppuccin_frappe";
      editor = {
        soft-wrap.enable = true;
        color-modes = true;
        line-number = "relative";
        bufferline = "multiple";
        indent-guides.render = true;
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          language-servers = [
            "nixd"
            "nil"
          ];
          formatter.command = "alejandra";
        }
      ];
      language-server.nixd = {
        command = "nixd";
      };
    };
    # themes."nix-${hash}" = import ./theme.nix { inherit colorscheme; };
  };
  xdg.configFile."helix/config.toml".onChange = ''
    ${pkgs.procps}/bin/pkill -u $USER -USR1 hx || true
  '';
}

{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;
    # theme = "catppuccin_frappe";
    settings = {
      general.live_config_reload = true;
      colors.primary= {
        foreground = "#d8d8d8";
        background = "#282c34";
      };
      font = {
        normal = {
          family = "FiraMono";
          style = "Regular";
        };
        size = 12;
      };
      mouse.hide_when_typing = true;
    };
  };

  home.packages = with pkgs; [
    fira
  ];

  xdg.mimeApps = {
    associations.added = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/terminal" = "Alacritty.desktop";
    };
  };
}

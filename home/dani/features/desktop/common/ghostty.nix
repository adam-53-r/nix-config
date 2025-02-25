{
  xdg.mimeApps = {
    associations.added = {
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    };
    defaultApplications = {
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    };
  };

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
  };
}
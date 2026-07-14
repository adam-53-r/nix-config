# Default browser. (main carried a large commented-out declarative profile —
# dead code, dropped; it lives on in main's git history if ever wanted.)
{
  flake.homeModules.homeFirefox = {
    programs.browserpass.enable = true;
    programs.firefox.enable = true;

    home.persistence."/persist".directories = [".mozilla"];

    xdg.mimeApps.defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
    };
  };
}

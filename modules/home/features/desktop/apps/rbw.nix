{
  flake.homeModules.homeRbw = {pkgs, ...}: {
    programs.rbw = {
      enable = true;
      settings = {
        email = "adam-53-r@protonmail.com";
        lock_timeout = 900;
        pinentry = pkgs.pinentry-qt;
      };
    };
    # rbw's own edit drops the per-item key, so rbw-picker edits through bw.
    home.packages = [
      pkgs.bitwarden-cli
      pkgs.rbw-picker
    ];
    # The cache db holds the login tokens and the data dir the device id, so
    # losing either means logging in again as a new device. Same for bw.
    home.persistence."/persist".directories = [
      ".cache/rbw"
      ".local/share/rbw"
      ".config/Bitwarden CLI"
    ];
  };
}

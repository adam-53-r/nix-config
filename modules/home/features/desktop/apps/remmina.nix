{
  flake.homeModules.homeRemmina = {pkgs, ...}: {
    home.packages = [pkgs.remmina];
    home.persistence."/persist".directories = [
      ".config/remmina"
      ".local/share/remmina"
    ];
  };
}

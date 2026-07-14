# GNS3 GUI; projects and settings survive the ephemeral root.
{
  flake.homeModules.homeGns3 = {pkgs, ...}: {
    home.packages = [pkgs.gns3-gui];
    home.persistence."/persist".directories = [
      ".config/GNS3"
      "GNS3"
    ];
  };
}

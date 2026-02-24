{pkgs, ...}: {
  imports = [
    ./global
    ./features/productivity/syncthing.nix
  ];
}

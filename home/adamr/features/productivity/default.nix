{pkgs, ...}: {
  imports = [
    ./syncthing.nix
    # TODO: broken
    # ./khal.nix
    # ./khard.nix
    # ./todoman.nix
    # ./vdirsyncer.nix

    # ./mail.nix
    # ./neomutt.nix

    # Pass feature is required
    # ../pass
  ];

  home.packages = with pkgs; [
    wpsoffice
  ];
}

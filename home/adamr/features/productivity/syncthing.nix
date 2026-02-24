{
  services.syncthing = {
    enable = true;
  };

  home.persistence = {
    "/persist".directories = [".local/state/syncthing"];
  };
}

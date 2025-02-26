{
  virtualisation.docker = {
    enable = true;
  };
  users.groups.docker = {};

  environment.persistence = {
    "/persist".directories = ["/var/lib/docker"];
  };
}

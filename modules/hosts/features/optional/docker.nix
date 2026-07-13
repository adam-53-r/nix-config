# Docker daemon (podman is the global default; this is for the tools that
# insist on real docker).
{
  flake.nixosModules.optionalDocker = {
    key = "mynix#nixosModules.optionalDocker";

    virtualisation.docker.enable = true;
    users.groups.docker = {};

    environment.persistence = {
      "/persist".directories = ["/var/lib/docker"];
    };
  };
}

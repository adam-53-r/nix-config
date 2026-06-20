# Rootless-capable Podman with docker CLI compatibility, shared by every host.
# dockerCompat/dockerSocket are disabled automatically if the real docker daemon
# is enabled on a host.
{...}: {
  flake.nixosModules.globalPodman = {config, ...}: let
    dockerEnabled = config.virtualisation.docker.enable;
  in {
    virtualisation.podman = {
      enable = true;
      dockerCompat = !dockerEnabled;
      dockerSocket.enable = !dockerEnabled;
      defaultNetwork.settings.dns_enabled = true;
    };

    environment.persistence = {
      "/persist".directories = ["/var/lib/containers"];
    };
  };
}

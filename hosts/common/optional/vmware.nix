{
  lib,
  pkgs,
  ...
}: {
  virtualisation.vmware.host.enable = true;

  environment.persistence = {
    "/persist".directories = [
      "/etc/vmware"
      "/var/log/vmware"
    ];
  };
}

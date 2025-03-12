{
  lib,
  pkgs,
  ...
}: {
  # Make sure ubridge exists
  users.groups.ubridge = {};

  security.wrappers.ubridge = {
    source = "${pkgs.ubridge}/bin/ubridge";
    capabilities = "cap_net_admin,cap_net_raw+ep";
    owner = "root";
    group = "ubridge";
    permissions = lib.mkForce "u+rx,g+rx,o+r";
  };

  environment.persistence = {
    "/persist" = {
      directories = [
        {
          directory = "/var/lib/gns3";
          user = "gns3";
          group = "gns3";
        }
      ];
    };
  };

}
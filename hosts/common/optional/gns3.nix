{
  lib,
  pkgs,
  ...
}: {
  # Make sure ubridge exists
  users.groups.ubridge = {};

  security.wrappers.ubridge = lib.mkDefault {
    capabilities = "cap_net_raw,cap_net_admin=eip";
    group = "ubridge";
    owner = "root";
    permissions = "u=rwx,g=rx,o=r";
    source = lib.getExe pkgs.ubridge;
  };

  environment.systemPackages = with pkgs; [
    gns3-server
    vpcs
    dynamips
  ];
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

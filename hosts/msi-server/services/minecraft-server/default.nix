{...}: let
  minecraft-home = "/DATA/msi-server/minecraft";
in {
  users.users.minecraft = {
    isNormalUser = true;
    home = minecraft-home;
    createHome = true;
    group = "minecraft";
    linger = true;
    extraGroups = ["podman"];
  };

  users.groups.minecraft = {};

  virtualisation.oci-containers.containers = {
    minecraft-server-cursedwalking-3_1_1 = {
      autoStart = false;
      image = "itzg/minecraft-server";
      autoRemoveOnStop = false;
      podman.user = "minecraft";
      ports = [
        "25565:25565/tcp"
        "24454:24454/udp"
      ];
      environment = {
        EULA = "TRUE";
        TYPE = "FORGE";
        UID = "0";
        GID = "0";
        MEMORY = "4G";
        VERSION = "1.20.1";
        FORGE_VERSION = "47.4.0";
        ENABLE_AUTOPAUSE = "TRUE";
      };
      volumes = [
        "${minecraft-home}/servers/cursedwalking_3.1.1/data:/data"
      ];
    };
  };
}

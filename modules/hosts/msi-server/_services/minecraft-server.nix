{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
  ];
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    servers.vanilla = {
      enable = true;
      jvmOpts = "-Xmx4G -Xms2G";
      serverProperties.online-mode = false;

      # Specify the custom minecraft server package
      package = pkgs.inputs.nix-minecraft.vanillaServers.vanilla-1_21_5;
    };
  };
}

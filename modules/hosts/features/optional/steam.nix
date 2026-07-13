# Steam + the gaming support that only matters alongside it (controller udev
# rules, gamemode).
{
  flake.nixosModules.optionalSteam = {
    key = "mynix#nixosModules.optionalSteam";

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    hardware.steam-hardware.enable = true;
    programs.gamemode.enable = true;
  };
}

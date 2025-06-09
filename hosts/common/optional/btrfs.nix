{
  lib,
  config,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = lib.mkDefault {
          type = "gpt";
          partitions = import ./partitions.nix hostname;
        };
      };
    };
  };
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
}

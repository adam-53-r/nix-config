{
  lib,
  config,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
  old_partitions = import ./partitions.nix hostname;
  old_root = old_partitions."${hostname}";
  new_partitions = builtins.removeAttrs old_partitions ["${hostname}"] // {
    "${hostname}_crypt" = {
      size = "100%";
      content = {
        type = "luks";
        name = "crypted";
        # disable settings.keyFile if you want to use interactive password entry
        #passwordFile = "/tmp/secret.key"; # Interactive
        # settings = {
        #   keyFile = "/dev/sda";
        #   allowDiscards = true;
        #   keyFileSize = 4096;
        #   keyFileTimeout = 30;
        #   # fallbackToPassword = true;
        #   # preLVM = false; # If this is true the decryption is attempted before the postDeviceCommands can run
        # };
        # additionalKeyFiles = [ "/dev/sda" ];
        content = old_root.content;
      };
    };
  };
in {
  disko.devices.disk.main.content = {
    type = "gpt";
    partitions = new_partitions;
  };
}
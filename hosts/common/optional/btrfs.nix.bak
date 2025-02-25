{
  config,
  lib,
  ...
}: let
  hostname = config.networking.hostName;
in {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "BOOT";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "/test" = {
                    mountpoint = "/test";
                    mountOptions = [ "compress=zstd" ];
                  };
                };
              };
            };
            # encryptedSwap = {
            #   size = lib.mkDefault "10G";
            #   content = {
            #     type = "swap";
            #     randomEncryption = true;
            #     priority = 100; # prefer to encrypt as long as we have space for it
            #   };
            # };
            # testpartition = {
            #   size = "1G";
            #   content = {
            #     type = "filesystem";
            #     format = "ext4";
            #     mountpoint = "/testpartition";
            #   };
            # };
          };
        };
      };
    };
    # nodev = {
    #   "/tmp" = {
    #     fsType = "tmpfs";
    #     mountOptions = [
    #       "size=200M"
    #     ];
    #   };
    # };
  };
}

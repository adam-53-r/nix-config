# This file contains an ephemeral btrfs root configuration
{
  lib,
  config,
  inputs,
  ...
}: let
  hostname = config.networking.hostName;
  wipeScript = ''
    mkdir /tmp -p
    MNTPOINT=$(mktemp -d)
    (
      mount -t btrfs -o subvol=/ /dev/mapper/crypted "$MNTPOINT"
      trap 'umount "$MNTPOINT"' EXIT

      echo "Creating needed directories"
      mkdir -p "$MNTPOINT"/persist/var/{log,lib/{nixos,systemd}}
      if [ -e "$MNTPOINT/persist/dont-wipe" ]; then
        echo "Skipping wipe"
      else
        echo "Cleaning root subvolume"
        btrfs subvolume list -o "$MNTPOINT/root" | cut -f9 -d ' ' | sort |
        while read -r subvolume; do
          btrfs subvolume delete "$MNTPOINT/$subvolume"
        done && btrfs subvolume delete "$MNTPOINT/root"

        echo "Restoring blank subvolume"
        btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
      fi
    )
  '';
  phase1Systemd = config.boot.initrd.systemd.enable;
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.initrd = {
    supportedFilesystems = ["btrfs"];
    postDeviceCommands = lib.mkIf (!phase1Systemd) (lib.mkBefore wipeScript);
    systemd.services.restore-root = lib.mkIf phase1Systemd {
      description = "Rollback btrfs rootfs";
      wantedBy = ["initrd.target"];
      requires = ["dev-mapper-crypted.device"];
      after = [
        "dev-mapper-crypted.device"
        "systemd-cryptsetup@crypted.service"
      ];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };
  };

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
                mountOptions = ["umask=0077"];
              };
            };

            "${hostname}_crypt" = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # disable settings.keyFile if you want to use interactive password entry
                #passwordFile = "/tmp/secret.key"; # Interactive
                settings = {
                  keyFile = "/dev/sda";
                  allowDiscards = true;
                  keyFileSize = 4096;
                  keyFileTimeout = 30;
                  # fallbackToPassword = true;
                  # preLVM = false; # If this is true the decryption is attempted before the postDeviceCommands can run
                };
                # additionalKeyFiles = [ "/dev/sda" ];
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd" "discard=async" "autodefrag"];
                    };
                    "/root-blank" = {};
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["compress=zstd" "noatime" "discard=async" "autodefrag"];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["compress=zstd" "discard=async" "autodefrag"];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      mountOptions = ["noatime"];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
}

# What changes when blacksite is run as a throwaway QEMU VM rather than
# installed to a disk:
#
#   nixos-rebuild build-vm --flake .#blacksite && ./result/bin/run-blacksite-vm
#
# qemu-vm.nix already replaces `fileSystems` and `swapDevices` wholesale
# (mkVMOverride), so disko's layout drops out on its own. The two things it
# cannot know about are this config's ephemeral-root rollback and its
# impermanence bind mounts — both point at a partition that does not exist in
# the build-vm variant, and both have to be switched off here explicitly.
#
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# blacksiteConfiguration in ./default.nix.
{lib, ...}: {
  virtualisation.vmVariant = {
    virtualisation = {
      # ghidra and burpsuite are both JVM hogs, and metasploit + a target
      # container on top of that makes 4G miserable.
      memorySize = 8192;
      cores = 4;
      # Sparse qcow2 created on first run, so this is a ceiling. The system
      # closure alone (wordlists, ghidra, the python env) is several GB.
      diskSize = 40960;

      graphics = true;
      # virtio-vga instead of qemu's default std VGA: XFCE gets a resizable
      # display and a far less painful redraw rate.
      qemu.options = ["-vga virtio"];

      # User-mode networking can't be reached from the host, so forward a port
      # for the headless workflow: `ssh -X -p 2222 adamr@localhost`.
      # Key auth only (PasswordAuthentication is off globally), against the
      # public keys userAdamr installs.
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };

    # The initrd rollback service waits on
    # /dev/disk/by-partlabel/disk-main-blacksite, which the build-vm variant
    # never creates — without this the VM hangs in stage 1. The variant is
    # already throwaway (its disk image is scratch), so nothing is lost.
    hardware.disko-btrfs.ephemeral = lib.mkForce false;

    # Likewise there is no /persist partition to bind-mount out of, at either
    # level: the NixOS-wide paths from globalPersistence, and adamr's home
    # dirs, which adamr@blacksite opts into.
    environment.persistence."/persist".enable = lib.mkForce false;
    home-manager.users.adamr.myPersistence.enable = lib.mkForce false;
  };
}

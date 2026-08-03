# pc hardware: AMD cpu+gpu desktop, luks+btrfs on nvme (layout owned by
# diskoBtrfs), limine boot with a Windows chainload entry.
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# pcConfiguration in ./default.nix.
{
  config,
  lib,
  ...
}: {
  boot = {
    initrd = {
      # r8169 drives the RTL8126 nic (enp16s0) - needed in initrd for network.ssh below.
      availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage" "r8169"];
      kernelModules = ["amdgpu"];
      # Unlock the luks root with a FIDO2 key, falling back to the passphrase.
      luks.devices."pc" = {
        crypttabExtraOpts = ["fido2-device=auto"];
        allowDiscards = true;
        # Don't bounce IO through dm-crypt's kernel workqueues: on NVMe they
        # add queueing latency that makes the desktop stall under bulk
        # writes (the Cloudflare no_{read,write}_workqueue finding).
        bypassWorkqueues = true;
      };

      # LAN-reachable sshd in stage-1, so the passphrase can be typed in
      # remotely (e.g. after a Wake-on-LAN power-on) instead of at the
      # console. Deliberately kept interactive/knowledge-based rather than
      # TPM2 auto-unlock, which would decrypt for anyone with the powered-on
      # box in hand. Host key lives only at /etc/secrets/initrd on this
      # machine (never in git) - see docs/remote-unlock.md for setup.
      network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = ["/etc/secrets/initrd/ssh_host_ed25519_key"];
          # adamr's YubiKey-resident pubkeys, pulled from the host's own
          # openssh config (single source of truth: home/adamr/ssh.pub via
          # userAdamr) so the two never drift apart. command= triggers the
          # password prompt on connect instead of dropping to a shell.
          authorizedKeys =
            map (key: ''command="systemctl default" '' + key)
            (lib.filter (key: key != "") config.users.users.adamr.openssh.authorizedKeys.keys);
        };
      };

      systemd.network.networks."10-enp16s0" = {
        matchConfig.Name = "enp16s0";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "routable";
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;
      limine.extraEntries = ''
        /Windows
          protocol: efi
          path: uuid(e126e23c-49f9-4264-abff-18506d70a3af):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };

  # pc's root is ephemeral (wiped every boot) - without this, the initrd ssh
  # host key above would vanish on reboot and the next rebuild would silently
  # embed nothing. Mirrors desktopNetworking's NetworkManager persistence.
  environment.persistence."/persist".directories = [
    "/etc/secrets/initrd"
    # LACT's runtime GPU profiles (clocks, voltage curve, power/fan limits) —
    # see services.lact below.
    "/etc/lact"
  ];

  # WARNING: nvme enumeration has drifted since install — the live /boot is on
  # nvme0n1 today. This device is only used when disko FORMATS the disk;
  # double-check it before ever running disko against this machine.
  disko.devices.disk.main.device = lib.mkForce "/dev/nvme1n1";

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 32768;
      randomEncryption.enable = true;
    }
  ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  nixpkgs.hostPlatform.system = "x86_64-linux";

  # Requires BIOS "Resume By PCI-E Device" enabled + ErP disabled. enp16s0's
  # connection is an imperative NetworkManager profile (not nix-declared), so
  # this declarative setting may get overridden on connection activation -
  # verify with `ethtool enp16s0 | grep Wake-on` after a reboot, and fall
  # back to `nmcli connection modify "Wired connection" 802-3-ethernet.wake-on-lan magic`
  # if it doesn't stick. See docs/remote-unlock.md.
  networking.interfaces.enp16s0.wakeOnLan.enable = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];
  hardware.amdgpu = {
    initrd.enable = true;
    opencl.enable = true;
    overdrive = {
      enable = true;
      # Full sysfs power-state API (voltage curve, power limit) for LACT —
      # the conservative nixpkgs default (0xfffd7fff) blocks some of it.
      ppfeaturemask = "0xffffffff";
    };
  };
  services.lact.enable = true;
}

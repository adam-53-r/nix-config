{
  lib,
  nixos-generators,
  ...
}:
nixos-generators.nixosGenerate {
  system = "x86_64-linux";
  format = "install-iso";
  modules = [
    {
      users.users.nixos = {
        initialHashedPassword = lib.mkForce "$y$j9T$tRAkzHi9kpFVhiUg21FIQ0$mkHVaqB1A/Seq4NfGnZaBswCQNWQ/8FWPrVKR5Qo7zD";
        openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ./home/adamr/ssh.pub);
        extraGroups = [
          "networkmanager"
        ];
      };
      programs.fish.enable = true;
      networking.networkmanager.enable = true;
      security.pam.sshAgentAuth.enable = true;
      services.openssh = {
        enable = true;
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      boot = {
        initrd = {
          availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage"];
          kernelModules = ["kvm-intel"];
        };
        kernelModules = ["kvm-intel"];
      };
    }
  ];
}

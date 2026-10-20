{...}: {
  flake.nixosModules.ociRuntime = {
    config,
    lib,
    pkgs,
    ...
  }: {
    key = "mynix#nixosModules.ociRuntime";
    boot.kernelParams = [
      "nvme.shutdown_timeout=10"
      "nvme_core.shutdown_timeout=10"
      "console=tty1"
      "console=ttyAMA0,115200" # aarch64 / A1 — this is the load-bearing one
    ];

    boot.loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input --append serial
      terminal_output --append serial
    '';

    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
    boot.loader.grub.efiInstallAsRemovable = true;

    networking.timeServers = lib.mkDefault ["169.254.169.254"];
    networking.useNetworkd = lib.mkDefault true;
    services.openssh.enable = true;

    systemd.services.fetch-ssh-keys = {
      description = "Fetch authorized_keys for root user";
      wantedBy = ["sshd.service"];
      before = ["sshd.service"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [pkgs.coreutils pkgs.curl];
      script = ''
        mkdir -m 0700 -p /root/.ssh
        if [ ! -f /root/.ssh/authorized_keys ]; then
          curl -s -S -L \
            -H "Authorization: Bearer Oracle" \
            -o /root/.ssh/authorized_keys \
            http://169.254.169.254/opc/v2/instance/metadata/ssh_authorized_keys
          chmod 600 /root/.ssh/authorized_keys
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardError = "journal+console";
        StandardOutput = "journal+console";
      };
    };
  };
}

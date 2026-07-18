# KVM/libvirt virtualisation with virt-manager and USB redirection.
{
  flake.nixosModules.optionalLibvirtd = {
    key = "mynix#nixosModules.optionalLibvirtd";

    virtualisation = {
      libvirtd = {
        enable = true;
        onBoot = "start";
      };
      spiceUSBRedirection.enable = true;
    };

    programs.virt-manager.enable = true;

    networking.firewall.interfaces.virbr0 = {
      allowedUDPPorts = [
        # DNS
        53
        # DHCP
        67
      ];
    };

    environment.persistence = {
      "/persist".directories = ["/var/lib/libvirt"];
    };
  };
}

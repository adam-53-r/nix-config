{
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  networking.firewall = {
    # Allows individual ports through the firewall.
    interfaces = {
      virbr0 = {
        allowedUDPPorts = [
          # DNS
          53
          # DHCP
          67
        ];
      };
    };
  };

  environment.persistence = {
    "/persist".directories = ["/var/lib/libvirt"];
  };
}

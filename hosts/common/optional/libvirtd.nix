{
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  environment.persistence = {
    "/persist".directories = ["/var/lib/libvirt"];
  };
}

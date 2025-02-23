{
  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "start";
      qemu.ovmf.enable = true;
    };
    spiceUSBRedirection.enable = true;
  };
  
  programs.virt-manager.enable = true;
}
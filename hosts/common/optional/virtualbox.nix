{
  pkgs,
  ...
}: {
  virtualisation.virtualbox.host = {
    enable = true;
    enableKvm = false;
    enableExtensionPack = true;
    addNetworkInterface = true;
    package = pkgs.virtualbox;
  };
  boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];
}

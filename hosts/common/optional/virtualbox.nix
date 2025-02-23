{
  pkgs,
  ...
}: {
  virtualisation.virtualbox.host = {
    enable = true;
    # enableKvm = true;
    enableExtensionPack = true;
    addNetworkInterface = true;
    package = pkgs.stable.virtualbox;

  };
}
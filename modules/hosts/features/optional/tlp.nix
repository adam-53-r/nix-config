# TLP battery/power heuristics for laptops, with USB autosuspend disabled so
# peripherals (YubiKey included) don't flake out on idle. Desktops skip TLP
# and carry only the kernel param (see the pc host).
{
  flake.nixosModules.optionalTlp = {
    key = "mynix#nixosModules.optionalTlp";

    services.tlp = {
      enable = true;
      settings = {
        USB_AUTOSUSPEND = 0;
      };
    };
    boot.kernelParams = ["usbcore.autosuspend=-1"];
  };
}

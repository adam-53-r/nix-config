{
  services.tlp = {
    enable = true;
    settings = {
      USB_AUTOSUSPEND = 0;
    };
  };
  boot.kernelParams = ["usbcore.autosuspend=-1"]; # or 120 to wait two minutes, etc
}

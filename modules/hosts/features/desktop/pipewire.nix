# Audio via pipewire (pulse/alsa/jack compatibility layers included).
{
  flake.nixosModules.desktopPipewire = {
    key = "mynix#nixosModules.desktopPipewire";

    security.rtkit.enable = true;
    services.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}

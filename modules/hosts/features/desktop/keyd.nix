# Caps<->Esc swap via keyd. Remaps at the evdev level, so it holds in X11,
# Wayland and the console alike — no per-DE xkb fiddling.
{
  flake.nixosModules.desktopKeyd = {
    key = "mynix#nixosModules.desktopKeyd";

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = ["*"];
        settings.main = {
          capslock = "esc";
          esc = "capslock";
        };
      };
    };
  };
}

# Caps<->Esc swap via keyd. Remaps at the evdev level, so it holds in X11,
# Wayland and the console alike — no per-DE xkb fiddling.
{
  flake.nixosModules.desktopKeyd = {
    key = "mynix#nixosModules.desktopKeyd";

    services.keyd = {
      enable = true;
      keyboards.default = {
        # Not the Corne (QMK's default feed:0000): it has its own layout, and its Caps key selects US/ES
        ids = ["*" "-feed:0000"];
        settings.main = {
          capslock = "esc";
          esc = "capslock";
        };
      };
    };
  };
}

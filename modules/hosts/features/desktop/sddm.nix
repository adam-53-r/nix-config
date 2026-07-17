# SDDM display manager with the astronaut theme. Also owns the X11/xkb
# baseline since SDDM's greeter still runs on X.
{self, ...}: {
  flake.nixosModules.desktopSddm = {pkgs, ...}: {
    key = "mynix#nixosModules.desktopSddm";

    imports = [self.nixosModules.sddmAstronautTheme];

    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
      # Never blank/suspend the display from X11 (the wayland side handles
      # idling via swayidle; the cinnamon fallback session shouldn't sleep
      # screens either).
      serverFlagsSection = ''
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
      '';
    };

    services.displayManager.sddm = {
      enable = true;
      autoNumlock = true;
      package = pkgs.kdePackages.sddm;
      extraPackages = with pkgs; [
        kdePackages.qtsvg
        kdePackages.qtmultimedia
        kdePackages.qtvirtualkeyboard
        libxcb
      ];
      astronaut-theme = {
        enable = true;
        config = "pixel_sakura.conf";
      };
    };
  };
}

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

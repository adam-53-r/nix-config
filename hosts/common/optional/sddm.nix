{
  pkgs,
  ...
}: {

  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  services.displayManager.sddm = {
    enable = true;
    # wayland.enable = true;
    autoNumlock = true;
    package = pkgs.kdePackages.sddm;
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
      xorg.libxcb
    ];
    theme = "sddm-astronaut-theme";
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    # sddm-sugar-dark
    # sddm-chili-theme
  ];
}
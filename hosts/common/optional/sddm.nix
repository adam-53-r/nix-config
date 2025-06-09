{pkgs, ...}: {
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
    astronaut-theme = {
      enable = true;
      config = "pixel_sakura.conf";
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    # sddm-sugar-dark
    # sddm-chili-theme
  ];
}

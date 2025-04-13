{
  pkgs,
  ...
}: {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
    uwsm.enable = true;
    hyprlock.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wofi
    wofi-emoji
    wl-clipboard
  ];
}
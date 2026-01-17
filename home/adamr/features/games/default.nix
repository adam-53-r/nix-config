{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./steam.nix
    ./prism-launcher.nix
    ./mangohud.nix
  ];
  home = {
    packages = with pkgs; [gamescope];
    persistence = {
      "/persist" = {
        # allowOther = true;
        directories = [
          "Games"
        ];
      };
    };
  };
}

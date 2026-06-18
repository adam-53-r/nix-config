{
  pkgs,
  config,
  lib,
  ...
}: let
  enable = pkgs.stdenv.hostPlatform.system != "aarch64-linux";
in {
  home.packages = lib.mkIf enable (with pkgs; [
    wineWowPackages.stable  # 32 + 64-bit WoW64 build
    winetricks
  ]);

  home.persistence = lib.mkIf enable {
    "/persist".directories = [".wine"];
  };
}

{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = lib.mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") [pkgs.wine];
  home.persistence = lib.mkIf (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
    "/persist/${config.home.homeDirectory}".directories = [".wine"];
  };
}

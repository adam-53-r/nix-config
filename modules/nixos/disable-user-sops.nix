{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.displayManager.sddm.astronaut-theme;
in {
  options.disable-user-sops = mkEnableOption "";
}
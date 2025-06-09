{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.displayManager.sddm.astronaut-theme;
in {
  options.services.displayManager.sddm.astronaut-theme = {
    enable = mkEnableOption "Sddm astronaut theme";
    config = let
      # Getting the possible configs for the theme by just listing the files in the Themes folder
      configs = map (c: builtins.baseNameOf c) (lib.filesystem.listFilesRecursive "${pkgs.sddm-astronaut}/share/sddm/themes/sddm-astronaut-theme/Themes");
    in
      mkOption {
        default = "astronaut.conf";
        type = lib.types.enum configs;
      };
  };

  config = mkIf cfg.enable {
    services.displayManager.sddm.theme = "sddm-astronaut-theme";
    environment.systemPackages = with pkgs; [
      (sddm-astronaut.overrideAttrs (oldAttrs: {
        installPhase = let
          basePath = "$out/share/sddm/themes/sddm-astronaut-theme";
        in
          oldAttrs.installPhase
          + ''
            ${pkgs.sd}/bin/sd 'ConfigFile=Themes/astronaut.conf' 'ConfigFile=Themes/${cfg.config}' ${basePath}/metadata.desktop;
          '';
      }))
    ];
  };
}

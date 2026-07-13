# Reusable option module: services.displayManager.sddm.astronaut-theme.
# Selects one of the sddm-astronaut theme's bundled configs by patching the
# theme package's metadata.
{
  flake.nixosModules.sddmAstronautTheme = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.services.displayManager.sddm.astronaut-theme;
    in {
      key = "mynix#nixosModules.sddmAstronautTheme";

      options.services.displayManager.sddm.astronaut-theme = {
        enable = mkEnableOption "Sddm astronaut theme";
        config = let
          # The possible configs for the theme, listed from its Themes folder
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
    };
}

# Fish shell with vendor completions/config/functions, shared by every host.
{...}: {
  flake.nixosModules.globalFish = {...}: {
    programs.fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };
  };
}

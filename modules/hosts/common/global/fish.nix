# Fish shell with vendor completions/config/functions, shared by every host.
{...}: {
  flake.nixosModules.globalFish = {...}: {
    key = "mynix#nixosModules.globalFish";
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

# GitHub CLI, shared optional home feature. Auth state (~/.config/gh) is
# persisted, gated behind myPersistence.enable.
{...}: {
  flake.homeModules.homeGh = {config, ...}: {
    programs.gh = {
      enable = true;
      settings = {
        version = "1";
        git_protocol = "ssh";
      };
    };

    home.persistence."/persist".directories = [
      ".config/gh"
    ];
  };
}

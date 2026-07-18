# Per-host home profile: adamr inside WSL. Full workstation CLI minus wine
# (Windows is right there), no persistence (no ephemeral root), and a separate
# work-flavoured git identity/signing key.
{self, ...}: {
  flake.homeModules."adamr@wsl" = {lib, ...}: {
    imports = [
      self.homeModules.adamrHome
      self.homeModules.cliWorkstation
      self.homeModules.homeProductivity
      self.homeModules.homePass
    ];

    myWine.enable = false;

    gtk.enable = true;

    programs.git = {
      settings.user.name = lib.mkForce "Adam Rkouni (WSL NixOS)";
      signing.key = lib.mkForce "E11BFA7CD08E29E121814B554C9AF4FAC826B53E";
      includes = [{path = "local.conf";}];
    };
    # Keep jujutsu signing with the same host-specific key.
    programs.jujutsu.settings.signing.key = lib.mkForce "E11BFA7CD08E29E121814B554C9AF4FAC826B53E";

    programs.ssh.includes = ["local.conf"];
  };
}

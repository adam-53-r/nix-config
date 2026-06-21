# adamr's host-agnostic home profile: the identity-free cliBase plus the shared
# optional features adamr actually uses (gpg-agent/smartcard, ssh, gh) and the
# personal identity layer. Per-host profiles (e.g. adamr-oci) import this and add
# host-specific bits like enabling persistence.
{self, ...}: {
  flake.homeModules.adamrHome = {...}: {
    imports = [
      self.homeModules.cliBase
      self.homeModules.homeGpg
      self.homeModules.homeSsh
      self.homeModules.homeGh
      self.homeModules.adamrIdentity
    ];

    home.username = "adamr";
    home.homeDirectory = "/home/adamr";
  };
}

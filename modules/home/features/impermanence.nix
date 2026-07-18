# Opt-in home-manager persistence (impermanence), shared optional feature.
#
# The impermanence home-manager module is auto-imported for every user by the
# impermanence NixOS module (pulled in via globalPersistence), so `home.persistence`
# is already available; this feature just adds the `myPersistence.enable` toggle
# that gates whether the colocated dirs (declared by other features) are actually
# bind-mounted. A per-host profile flips it on for ephemeral hosts (oci) and
# leaves it off elsewhere — matching how the main-branch config toggles it.
#
# Per the current impermanence API the storage path is just "/persist"; the
# user's home dir is appended automatically (→ /persist/home/adamr, /persist/root).
{...}: {
  flake.homeModules.homeImpermanence = {
    lib,
    config,
    ...
  }: {
    options.myPersistence.enable =
      lib.mkEnableOption "opt-in home-manager persistence to /persist";

    config.home.persistence."/persist".enable = config.myPersistence.enable;
  };
}

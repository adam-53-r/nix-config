# flake-parts pre-declares `flake.nixosModules` as a mergeable attrset, but not
# `flake.homeModules`. Declare it here so multiple module files can each
# contribute home-manager profiles (cliBase, adamr, …) without conflicting.
{lib, ...}: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    description = "home-manager profile modules exposed by this flake.";
  };
}

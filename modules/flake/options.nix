# flake-parts pre-declares `flake.nixosModules` as a mergeable attrset, but not
# `flake.homeModules`. Declare it here so multiple module files can each
# contribute home-manager profiles without conflicting.
#
# Every entry is wrapped with a unique `key` so the same module can be imported
# through several paths and still deduplicate (anonymous modules don't:
# importing an option-declaring module twice fails with "option already
# declared", and duplicated config gets merged twice). flake-parts does the
# same `_file` wrapping for nixosModules, but sets no `key`, and `_file` does
# not participate in deduplication — so nixosModules carry explicit `key`
# attributes instead.
{
  lib,
  moduleLocation,
  ...
}: {
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
    apply = lib.mapAttrs (name: module: {
      _file = "${toString moduleLocation}#homeModules.${name}";
      key = "mynix#homeModules.${name}";
      imports = [module];
    });
    description = "home-manager profile modules exposed by this flake.";
  };
}

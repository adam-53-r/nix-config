# Expose the overlays (flake inputs aliases, stable channel, custom packages
# and package modifications) as flake outputs. They are applied to every host
# in the globalDefaults module.
{inputs, ...}: {
  flake.overlays = import ../../overlays {inherit inputs;};
}

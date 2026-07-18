# Advertise this host as a tailnet exit node (tailscale itself comes from
# globalTailscale in the globalDefaults baseline).
{
  flake.nixosModules.optionalTailscaleExitNode = {
    key = "mynix#nixosModules.optionalTailscaleExitNode";

    services.tailscale = {
      useRoutingFeatures = "both";
      extraUpFlags = ["--advertise-exit-node"];
    };
  };
}

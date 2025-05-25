{inputs, config, ...}: {
  system.hydraAutoUpgrade = {
    # Only enable if not dirty
    enable = inputs.self ? rev;
    dates = "weekly";
    instance = "https://hydra.arm53.xyz";
    project = "nix-config";
    jobset = "main";
    job = "hosts.${config.networking.hostName}";
    oldFlakeRef = "self";
  };
}

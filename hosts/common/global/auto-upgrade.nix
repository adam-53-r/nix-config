{inputs, config, ...}: {
  system.hydraAutoUpgrade = {
    # Only enable if not dirty
    enable = inputs.self ? rev;
    dates = "*:0/10"; # Every 10 minutes
    # instance = "https://hydra.m7.rs";
    project = "nix-config";
    jobset = "main";
    job = "hosts.${config.networking.hostName}";
    oldFlakeRef = "self";
  };
}

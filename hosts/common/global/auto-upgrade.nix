{
  inputs,
  config,
  ...
}: {
  system.hydraAutoUpgrade = {
    # Only enable if not dirty
    # enable = inputs.self ? rev;
    enable = false;
    dates = "weekly";
    instance = "https://hydra.arm53.xyz";
    project = "nix-config";
    jobset = "main";
    job = "hosts.${config.networking.hostName}";
    oldFlakeRef = "self";
  };

  system.autoUpgrade = {
    # Only enable if not dirty
    # enable = inputs.self ? rev;
    enable = false;
    flake = "github:adam-53-r/nix-config#${config.networking.hostName}";
    operation = "boot";
    runGarbageCollection = true;
    dates = "*-*-* *:*10,5:00";
    allowReboot = true;
    rebootWindow = {
      lower = "00:00";
      upper = "23:00";
    };
  };
}

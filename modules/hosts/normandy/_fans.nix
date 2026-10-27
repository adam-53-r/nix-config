# MSI X870E fan control. The board's NCT6687-R has no in-tree driver, so the
# CPU and case fans are invisible to Linux and the BIOS curve runs them at
# ~52%/~69% at idle. nct6687d + CoolerControl take them over.

{config, ...}: {
  boot = {
    extraModulePackages = [config.boot.kernelPackages.nct6687d];
    kernelModules = ["nct6687"];
    # Without this the EC re-applies its own curve over pwm writes on the case
    # headers (the CPU header sticks either way); brute force writes all 7
    # curve points instead, which it honours. The driver picks the right X870
    # system-fan registers by itself
    extraModprobeConfig = ''
      options nct6687 msi_fan_brute_force=1
    '';
  };

  programs.coolercontrol.enable = true;

  # CoolerControl stores config.toml, per-device settings and its TLS certs
  # here, and it is the UI that writes them
  environment.persistence."/persist".directories = ["/etc/coolercontrol"];
}

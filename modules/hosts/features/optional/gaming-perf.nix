# CPU-side gaming tuning, complementing optionalSteam (which handles the
# stack) and LACT (which handles the GPU).
{
  flake.nixosModules.optionalGamingPerf = {
    key = "mynix#nixosModules.optionalGamingPerf";

    # Split-lock detection defaults to "warn", which punishes offending
    # threads with a ~10ms busy-wait — several Windows games (via Proton)
    # trip it constantly and stutter. No security impact on a single-user
    # desktop.
    boot.kernelParams = ["split_lock_detect=off"];

    # Dual-CCD X3D CPUs (9950X3D): amd_3d_vcache boots in "frequency" mode,
    # steering threads to the non-V-Cache CCD first. Cache-bound game loops
    # (Unity/KSP physics) want the opposite. "cache" only changes which CCD
    # fills first — all-core loads like nix builds still use both.
    # No-op on hardware without the AMDI0101 platform device.
    services.udev.extraRules = ''
      ACTION=="add|bind", SUBSYSTEM=="platform", KERNEL=="AMDI0101:00", ATTR{amd_x3d_mode}="cache"
    '';

    # gamemoderun already raises the cpufreq governor to performance; also
    # renice the game so background load can't steal its timeslices.
    programs.gamemode.settings.general.renice = 10;
  };
}

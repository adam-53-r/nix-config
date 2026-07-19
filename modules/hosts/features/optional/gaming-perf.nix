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
    #
    # NVMe defaults to the "none" scheduler: bulk writes and interactive
    # reads share one FIFO queue, so a Steam/CKAN download starves the
    # desktop. mq-deadline prioritizes reads (500ms vs 5s expiry) and honors
    # ionice classes (kernel >= 5.17), letting bulk jobs be demoted to idle.
    services.udev.extraRules = ''
      ACTION=="add|bind", SUBSYSTEM=="platform", KERNEL=="AMDI0101:00", ATTR{amd_x3d_mode}="cache"
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="mq-deadline"
    '';

    # gamemoderun already raises the cpufreq governor to performance; also
    # renice the game so background load can't steal its timeslices.
    programs.gamemode.settings.general.renice = 10;

    # With 60GiB RAM the default dirty_ratio lets ~12GiB of dirty pages pile
    # up, then writeback dam-bursts through LUKS+btrfs transaction commits and
    # stalls the whole desktop (felt during Steam/CKAN installs). Cap dirty
    # data so bulk writes flush continuously in small increments instead.
    boot.kernel.sysctl = {
      "vm.dirty_background_bytes" = 536870912; # 512MiB
      "vm.dirty_bytes" = 2147483648; # 2GiB
    };
  };
}

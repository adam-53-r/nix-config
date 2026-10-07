# pc memory and sleep policy, ported from avalon's _power.nix.
{lib, ...}: {
  ###### Memory / swap ######################################################

  # zram takes the normal paging load (compressed, in RAM, priority 5) while
  # the on-disk swapfile sits at a lower priority and stays reserved for the
  # hibernation image — neither the kernel nor systemd will ever hibernate
  # into a zram device, so the two coexist by design.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    # With zram, swapping is cheap (a memcpy plus zstd) and far preferable to
    # evicting page cache, so globalSwappiness's 60 is too shy. mkForce
    # because that module sets it as a plain value, not a default.
    "vm.swappiness" = lib.mkForce 150;
    # Swap readahead is pointless for zram — there is no seek to amortise and
    # every extra page costs a decompression.
    "vm.page-cluster" = 0;
  };

  ###### Suspend / hibernate ################################################
  services.logind.settings.Login = {
    HandlePowerKey = "suspend-then-hibernate";
    HandlePowerKeyLongPress = "poweroff";
    # Keyboards with a dedicated sleep key should degrade the same way.
    HandleSuspendKey = "suspend-then-hibernate";
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";

  ###### amdgpu S4 GTT swapout ##############################################

  # Since 6.17 amdgpu swaps all GTT buffers out on hibernate
  # (ttm_device_prepare_hibernation). That leaves TTM's LRU bulk-move cursors
  # pointing at freed memory, and the first GPU client to touch its buffers
  # after resume oopses holding the LRU lock -> every GPU client hangs, black
  # screen, hard reset. It's only an optimisation (smaller image), so drop it.
  # No upstream fix yet as of 7.1.11; recheck on kernel bumps.
  # Builds the kernel from source.
  boot.kernelPatches = [
    {
      name = "amdgpu-no-s4-gtt-swapout";
      patch = ./amdgpu-no-s4-gtt-swapout.patch;
    }
  ];
}

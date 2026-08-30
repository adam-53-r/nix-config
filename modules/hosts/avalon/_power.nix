# avalon power, thermal and battery-health policy.
#
# Three things happen here:
#   1. TLP + thermald own CPU/device power policy (power-profiles-daemon is
#      forced off in default.nix, and powertop's auto-tune is deliberately not
#      used — see below).
#   2. The machine can actually hibernate now, onto the encrypted swapfile
#      diskoBtrfs carves out, with the lid and the power key wired to
#      suspend-then-hibernate.
#   3. msi-ec talks to the MSI embedded controller, which is the only way to
#      get a charge limit on this chassis.
#
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# avalonConfiguration in ./default.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Stop charging here. Keeping an old cell off a 100% float charge is the
  # single biggest lever on its remaining life; raise to 100 temporarily when
  # full runtime is needed.
  chargeLimit = 80;
in {
  ###### CPU / thermal ######################################################

  # Intel's thermal daemon; nixos-hardware's common-cpu-intel does not enable
  # it. Without it the 8750H is left to the kernel's passive trip points
  # alone, which on a 15mm chassis means hitting the thermal ceiling and
  # throttling hard instead of being steered around it.
  services.thermald.enable = true;

  # TLP settings; optionalTlp already owns USB_AUTOSUSPEND=0 (YubiKey) and
  # the matching kernel param, so only the additions live here.
  services.tlp.settings = {
    # intel_pstate keeps "powersave" as the governor in both states — on HWP
    # hardware the energy/performance hints below are the real control, and
    # switching to "performance" just pins the floor high.
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    # TLP ships "power" as the on-battery default, which upstream itself
    # acknowledges is too aggressive on Intel (linrunner/TLP#460): it can hold
    # the cores low enough that interactive work feels sticky. balance_power
    # is the middle setting and the one worth living with.
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

    # Turbo off on battery is the single biggest win on a 45W H-series part:
    # it stops a busy browser tab from spinning the fans up. The max-perf caps
    # are left at 100 on purpose, since throttling sustained clock makes work
    # take longer and usually costs more energy overall (race to idle),
    # whereas cutting the 45W turbo spikes does not.
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_MAX_PERF_ON_BAT = 100;

    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";

    SOUND_POWER_SAVE_ON_AC = 0;
    SOUND_POWER_SAVE_ON_BAT = 1;

    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";

    PCIE_ASPM_ON_AC = "default";
    PCIE_ASPM_ON_BAT = "powersupersave";

    NMI_WATCHDOG = 0;
  };

  # powerManagement.powertop.enable is deliberately absent: running
  # `powertop --auto-tune` at boot alongside TLP is a combination TLP's own
  # documentation calls out as conflicting, since whichever runs last wins and
  # TLP re-applies its values on every power-source change regardless. powertop
  # stays installed as a measurement tool.
  environment.systemPackages = [pkgs.powertop];

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
    # evicting page cache, so the global default of 60 is too shy.
    "vm.swappiness" = lib.mkForce 150;
    # Swap readahead is pointless for zram — there is no seek to amortise and
    # every extra page costs a decompression.
    "vm.page-cluster" = 0;
  };

  ###### Suspend / hibernate ################################################

  # The keys here must be the Handle* ones. settings.Login is a freeform
  # passthrough into logind.conf, so a plausible-looking `lidSwitch = ...` is
  # emitted verbatim, ignored by systemd, and leaves lid behaviour silently
  # unconfigured rather than erroring.
  services.logind.settings.Login = {
    # Sleep to RAM first, then write the hibernation image and power off once
    # HibernateDelaySec has elapsed: a lid close stays instant without the
    # machine draining itself flat in a bag overnight.
    HandleLidSwitch = "suspend-then-hibernate";
    # On AC, a lid close usually means relocating rather than sleeping.
    HandleLidSwitchExternalPower = "lock";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend-then-hibernate";
    HandlePowerKeyLongPress = "poweroff";
  };

  systemd.sleep.settings.Sleep.HibernateDelaySec = "45min";

  # Running out of battery should preserve the session rather than drop it.
  # Hibernate is the non-risky critical action, unlike Suspend, which upstream
  # gates behind allowRiskyCriticalPowerAction.
  services.upower = {
    criticalPowerAction = "Hibernate";
    usePercentageForPolicy = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
  };

  ###### MSI embedded controller ############################################

  # The GS65's EC is only reachable through the out-of-tree msi-ec driver.
  # Upstream lists this exact board (msi-ec.c: "16Q4EMS1.110", GS65 Stealth
  # 8S/9S), which exposes a battery charge limit, the fan/shift modes and
  # CPU/GPU temperature plus fan-speed sensors.
  #
  # The override is required because this unit's EC revision is newer than
  # anything upstream lists, so the driver refuses to bind with "msi_ec: Your
  # firmware version is not supported!" and no charge-limit attribute ever
  # appears. `firmware=` skips the EC version probe and loads the named
  # profile; 16Q4EMS1.110 is this board (the GS65 Stealth 8S/9S entry), and
  # the EC register map is per-board, so a point revision does not move it.
  boot.extraModulePackages = [config.boot.kernelPackages.msi-ec];
  boot.kernelModules = ["msi-ec"];
  boot.extraModprobeConfig = ''
    options msi_ec firmware=16Q4EMS1.110
  '';

  # msi-ec hangs the threshold attributes off the ACPI battery device, so the
  # rule fires whenever that device appears.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="BAT*", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_control_end_threshold}="${toString chargeLimit}"
  '';

  # Safety net for the ordering race where msi-ec registers its battery hook
  # after udev has already processed the battery device (and to re-assert the
  # limit after a firmware-level EC reset).
  systemd.services.msi-ec-charge-limit = {
    description = "Apply the MSI EC battery charge limit";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      applied=0
      for f in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
        [ -w "$f" ] || continue
        echo ${toString chargeLimit} > "$f"
        applied=1
      done
      if [ "$applied" = 0 ]; then
        echo "no writable charge_control_end_threshold found - is msi-ec loaded?" >&2
      fi
    '';
  };

  ###### Misc ###############################################################

  # MSI publishes little to LVFS for this vintage, but the daemon is cheap and
  # still covers the SSD and dock.
  services.fwupd.enable = true;

  # Don't power the radio on at boot; hypridle/uwsm bring it up when needed.
  hardware.bluetooth.powerOnBoot = false;
}

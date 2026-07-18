# USB/hardware peripherals: keyboard flashing, RGB control, bluetooth, and the
# USB autosuspend workaround that keeps them from flaking out when idle.
{pkgs, ...}: {
  # Disable USB autosuspend so peripherals (YubiKey included) don't flake out
  # after going idle. (main did this via services.tlp.settings, which also
  # applies laptop-battery power heuristics this desktop doesn't want — just
  # the kernel param is ported here.)
  boot.kernelParams = ["usbcore.autosuspend=-1"];

  hardware.bluetooth.powerOnBoot = false;

  # QMK/vial keyboard flashing without root.
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [
    (pkgs.writeTextDir "etc/udev/rules.d/59-vial.rules" ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '')
  ];

  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    package = pkgs.openrgb-with-all-plugins;
  };
}

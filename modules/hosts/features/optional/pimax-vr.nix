# Pimax Crystal Light (and the other P3C headsets) on Monado.
# https://vronlinux.org/docs/hardware/pimax/p3c/
{
  flake.nixosModules.optionalPimaxVr = {pkgs, ...}: {
    key = "mynix#nixosModules.optionalPimaxVr";

    # Marks the headset panel non-desktop so the compositor leaves it for
    # Monado to lease, and keeps the HID polled so the headset doesn't keep
    # reinitialising. Neither is upstream as of 7.2. Builds the kernel from
    # source.
    boot.kernelPatches = [
      {
        name = "pimax-vr";
        patch = ./pimax-vr.patch;
      }
    ];

    services.udev.packages = [
      (pkgs.writeTextDir "etc/udev/rules.d/60-pimax.rules" ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="34a4", MODE="0660", GROUP="users", TAG+="uaccess"
        KERNEL=="hidraw*", ATTRS{idVendor}=="34a4", MODE="0660", GROUP="users", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="2104", MODE="0660", GROUP="users", TAG+="uaccess"
        KERNEL=="hidraw*", ATTRS{idVendor}=="2104", MODE="0660", GROUP="users", TAG+="uaccess"
      '')
    ];

    services.monado = {
      enable = true;
      package = pkgs.monado-pimax;
      defaultRuntime = true;
    };

    environment.systemPackages = [pkgs.xrgears];
  };
}

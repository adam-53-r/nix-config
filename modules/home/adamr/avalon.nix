# Per-host home profile: adamr on the avalon laptop.
#
# Diverges from adamr@pc in three ways, all following from this being a
# portable machine: no games layer, a single-panel monitor layout that lets
# Hyprland auto-configure whatever gets plugged in, and a session pinned to
# the Intel iGPU to keep work off the dGPU (see _hardware.nix).
{self, ...}: {
  flake.homeModules."adamr@avalon" = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      self.homeModules.adamrHome
      self.homeModules.cliWorkstation

      self.homeModules.homeHyprland
      self.homeModules.homeCinnamon
      self.homeModules.homeWayvnc
      self.homeModules.homeTheming
      self.homeModules.homeProductivity
      self.homeModules.homePass
      self.homeModules.homeHelix
    ];

    # Ephemeral root → keep the colocated stateful dirs across reboots.
    myPersistence.enable = true;

    # The colorscheme for the whole session (hyprland borders, waybar, mako,
    # wofi, alacritty, gtk/qt) is generated from this image, so it is the
    # single knob that re-themes the machine. castle-mountains,
    # aenami-eternity and lowpoly-island are near neighbours of this one.
    wallpaper = pkgs.inputs.themes.wallpapers.castle-sunset-fantasy;

    # Host-local ssh tweaks live outside the store.
    programs.ssh.includes = ["local.conf"];

    # Just the internal panel. Declaring the full docked layout here would
    # describe outputs that are absent most of the time; anything plugged in
    # instead lands on the catch-all rule the hyprland module appends
    # (preferred mode, placed to the right).
    monitors = [
      {
        name = "eDP-1";
        width = 1920;
        height = 1080;
        workspace = "1";
        position = "0x0";
        primary = true;
        refreshRate = 144;
      }
    ];

    wayland.windowManager.hyprland.settings.env = [
      # Render on the iGPU, keep the dGPU node available so the HDMI/mini-DP
      # outputs (wired to the nvidia card on this chassis) still light up when
      # docked. These are the udev symlinks minted in _hardware.nix: this list
      # is colon-separated, so the /dev/dri/by-path names cannot be used here
      # (they contain colons and get shredded), and raw cardN is probe-order
      # dependent — on this machine nvidia is card0 and the iGPU card1.
      "AQ_DRM_DEVICES,/dev/dri/igpu:/dev/dri/dgpu"
      # Decode video on the Intel media stack. Pointing VA-API at nvidia
      # instead wakes the dGPU for every video played. Switch to i965 if iHD
      # misbehaves on Gen9.5; both drivers are installed (see
      # hardware.intelgpu in _hardware.nix).
      "LIBVA_DRIVER_NAME,iHD"
    ];
    # __GLX_VENDOR_LIBRARY_NAME=nvidia and NVD_BACKEND=direct are deliberately
    # unset: they force every GL client onto the dGPU. `nvidia-offload <cmd>`
    # sets them per-process for the programs that want it.

    home.persistence."/persist".directories = [
      ".config/Yubico"
    ];

    dconf.settings = {
      # homeCinnamon sets send-events = "disabled-on-external-mouse", which is
      # correct on a desktop but breaks the touchpad here: the I2C touchpad
      # exposes a sibling "...06CB:CDAD Mouse" device and psmouse probes a
      # phantom "PS/2 Synaptics TouchPad" on top, so Cinnamon always believes
      # an external mouse is attached and disables the real touchpad at
      # session start. X binds the device correctly (type: TOUCHPAD); libinput
      # is simply told to drop its events.
      "org/cinnamon/desktop/peripherals/touchpad".send-events = lib.mkForce "enabled";

      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [
          "qemu:///system"
          "qemu+ssh://adamr@msi-server/system"
        ];
        uris = [
          "qemu:///system"
          "qemu+ssh://adamr@msi-server/system"
        ];
      };
    };

    # No ~/.config/cinnamon-monitors.xml is written here. Cinnamon is the
    # fallback session and can work its own layout out, whereas a checked-in
    # file pins X11-era output names that drift out of step with the wayland
    # layout above.
  };
}

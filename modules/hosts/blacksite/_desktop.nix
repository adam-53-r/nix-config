# blacksite desktop: XFCE on X11 — what Kali itself ships, and the right call
# in a VM (light, no compositor games, and every GUI tool here was written and
# tested against it). Deliberately NOT desktopBase: Hyprland/uwsm + SDDM
# theming + the whole theming stack is a large closure for a scratch box, and
# X11 is what makes `ssh -X` work without ceremony.
#
# Also wires up the headless path, because the useful way to drive this VM from
# its host is often not the virt-manager console at all:
#
#   ssh -X blacksite burpsuite         # single tool onto the host's X/XWayland
#   waypipe ssh blacksite <app>        # ...or over waypipe, from a Wayland session
#
# Plain NixOS module (underscore file: skipped by import-tree), imported by
# blacksiteConfiguration in ./default.nix.
{pkgs, ...}: {
  services.xserver = {
    enable = true;
    desktopManager.xfce.enable = true;
    displayManager.lightdm.enable = true;
  };

  services.displayManager = {
    defaultSession = "xfce";
    # A greeter on a throwaway single-user lab VM is a speed bump, not a
    # security control — the password still guards ssh and the console.
    autoLogin = {
      enable = true;
      user = "adamr";
    };
  };

  # Persist XFCE's own settings (xfconf writes under ~/.config/xfce4) so panel
  # and appearance tweaks survive the ephemeral root; see adamr@blacksite.
  programs.xfconf.enable = true;

  # Thunar's trash/mount/thumbnail integration.
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  environment.systemPackages = with pkgs; [
    xfce4-terminal
    thunar
    xfce4-screenshooter
    xfce4-taskmanager
    # NetworkManager tray applet for the XFCE panel (openvpn imports, wifi if
    # an adapter gets passed through).
    networkmanagerapplet
    # X11 forwarding from the host: xauth is what sshd needs to set up the
    # cookie, waypipe for the Wayland-native path.
    xauth
    xhost
    waypipe
  ];

  # NetworkManager rather than the shared desktopNetworking module: that one
  # pins wifi.backend = "iwd", and for 802.11 auditing wpa_supplicant (the
  # default) coexists far better with monitor mode and airmon-ng. resolved is
  # skipped too — a scanning box wants plain, predictable resolv.conf.
  networking.networkmanager.enable = true;
  users.groups.networkmanager = {};

  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections"
  ];
}

# The blacksite host: a disposable cybersecurity practice lab, meant to run as
# a guest on pc (which already provides libvirtd/virt-manager).
#
# Two ways to run it, both from this one configuration:
#
#   nixos-rebuild build-vm --flake .#blacksite   -> throwaway QEMU VM, no install
#   nix build .#nixosConfigurations.blacksite.config.system.build.diskoImages
#                                                -> qcow2 to import into virt-manager
#
# See docs/blacksite-lab.md for the full workflow. The security toolbox itself
# is the reusable optionalSecurityTools module; everything here is host policy:
# what the lab is allowed to reach, what survives a reboot, and the
# conveniences that make a scratch box pleasant (autologin, passwordless sudo).
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.blacksiteConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.blacksiteConfiguration";

    imports = [
      self.nixosModules.globalDefaults
      self.nixosModules.diskoBtrfs
      self.nixosModules.userAdamr

      # The toolbox (every category on by default) plus the setcap dumpcap
      # wrapper, so wireshark captures without running the GUI as root.
      self.nixosModules.optionalSecurityTools
      self.nixosModules.optionalWireshark

      ./_hardware.nix
      ./_desktop.nix
      ./_lab.nix
      ./_vm-variant.nix
    ];

    networking.hostName = "blacksite";

    # Not enrolled in .sops.yaml (it has no host key until it's installed), so
    # it can't decrypt the shared adamr-password secret — same as vm/oci/wsl.
    disable-user-sops = true;

    # ...which leaves the account with no password at all, and none is set here
    # on purpose: this repo is public, and a literal hash is a credential in
    # git forever even when the cleartext is throwaway. The box stays usable
    # without one — lightdm autologins into XFCE, sshd accepts the keys
    # userAdamr installs, and sudo below needs no password.
    #
    # What that costs is the greeter after a logout and console login. To get
    # those back, keep the hash out of the tree rather than adding a literal:
    #
    #   sudo mkdir -p /persist/secrets
    #   mkpasswd -m yescrypt | sudo tee /persist/secrets/adamr-password
    #
    # and set hashedPasswordFile to that path (/persist survives the wipe), or
    # enroll the host in .sops.yaml and drop disable-user-sops above.

    # Half this toolbox is useless unprivileged (SYN scans, raw sockets,
    # monitor mode, tcpdump), and the box is a scratch VM whose root is wiped
    # every boot — typing a password for every one of those is pure friction.
    security.sudo.wheelNeedsPassword = false;

    # tailscaled comes from globalDefaults and runs, but nothing authenticates
    # it (no authKeyFile anywhere in this config), so the lab stays off the
    # tailnet until someone runs `tailscale up` — which is the right default: a
    # box full of scanners shouldn't sit one `nmap 100.64.0.0/10` away from
    # every other host. Routing features off too; a lab guest has no business
    # advertising routes or acting as an exit node.
    services.tailscale.useRoutingFeatures = "none";

    # This host has no business auto-upgrading itself from git; it's a scratch
    # box that gets rebuilt or thrown away by hand. (Already false globally —
    # pinned here so a future global flip doesn't silently include the lab.)
    system.autoUpgrade.enable = lib.mkForce false;

    system.stateVersion = "26.05";
  };
}

# SSH client defaults, shared optional home feature.
# Generic, identity-free client config. ~/.ssh (known_hosts etc.) is persisted
# here at mode 0700, gated behind myPersistence.enable.
{self, ...}: {
  flake.homeModules.homeSsh = {lib, ...}: let
    # Every configured NixOS host, plus its tailnet FQDN, so the `net` block
    # below matches connections to them by short name too.
    # TODO: derive the tailnet domain suffix dynamically instead of hardcoding.
    tailnetDomain = "tail6743b5.ts.net";
    hostnames = builtins.attrNames self.nixosConfigurations;
    netHosts = lib.concatStringsSep " " (
      lib.flatten (map (host: [host "${host}.${tailnetDomain}"]) hostnames)
    );
  in {
    programs.ssh = {
      enable = true;
      # Opt out of home-manager's soon-to-be-removed implicit defaults and set
      # our own global block.
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        # Multiplex connections so a control socket exists at
        # ~/.ssh/master-%r@%n:%p (used by hyprland's remote-launch keybinds).
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      # Tailnet hosts: forward the ssh agent, X11, and the gpg-agent socket
      # (paired with homeGpg's link-gnupg-sockets unit on the far end).
      settings.net = {
        header = "Host ${netHosts}";
        ForwardAgent = true;
        RemoteForward = {
          bind.address = "/%d/.gnupg-sockets/S.gpg-agent";
          host.address = "/%d/.gnupg-sockets/S.gpg-agent.extra";
        };
        ForwardX11 = true;
        ForwardX11Trusted = true;
        StreamLocalBindUnlink = "yes";
      };
    };

    home.persistence."/persist".directories = [
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
  };
}

# SSH client defaults, shared optional home feature.
# Generic, identity-free client config. ~/.ssh (known_hosts etc.) is persisted
# here at mode 0700, gated behind myPersistence.enable.
{...}: {
  flake.homeModules.homeSsh = {config, ...}: {
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

{
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  nixosConfigs = builtins.attrNames outputs.nixosConfigurations;
  homeConfigs = map (n: lib.last (lib.splitString "@" n)) (builtins.attrNames outputs.homeConfigurations);
  hostnames = lib.unique (homeConfigs ++ nixosConfigs);
in {
  home.persistence = {
    "/persist/${config.home.homeDirectory}" = {
      directories = [
        {
          directory = ".ssh";
          method = "bindfs";
        }
      ];
    };
  };

  home.packages = with pkgs; [sshfs];

  programs.ssh = {
    enable = true;
    # See above
    # userKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts.d/hosts";
    matchBlocks = {
      net = {
        host = lib.concatStringsSep " " (
          lib.flatten (map (host: [
              host
              "${host}.tail6743b5.ts.net"
              # "${host}.ts.m7.rs"
            ])
            hostnames)
        );
        forwardAgent = true;
        remoteForwards = [
          {
            bind.address = ''/%d/.gnupg-sockets/S.gpg-agent'';
            host.address = ''/%d/.gnupg-sockets/S.gpg-agent.extra'';
          }
          {
            bind.address = ''/%d/.waypipe/server.sock'';
            host.address = ''/%d/.waypipe/client.sock'';
          }
        ];
        forwardX11 = true;
        forwardX11Trusted = true;
        setEnv.WAYLAND_DISPLAY = "wayland-waypipe";
        extraOptions.StreamLocalBindUnlink = "yes";
      };
    };
  };

  # Compatibility with programs that don't respect SSH configurations (e.g. jujutsu's libssh2)
  # systemd.user.tmpfiles.rules = [
  #   "L ${config.home.homeDirectory}/.ssh/known_hosts - - - - ${config.programs.ssh.userKnownHostsFile}"
  # ];
}

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
  home.packages = with pkgs; [ sshfs ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      net = {
        host = lib.concatStringsSep " " (lib.flatten (map (host: [
            host
          ]) hostnames)
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
        extraOptions.StreamLocalBindUnlink = "yes";
      };
    };
  };
}
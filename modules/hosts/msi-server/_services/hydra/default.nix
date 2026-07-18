{
  pkgs,
  config,
  ...
}: let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;
in {
  imports = [
    ./machines.nix
  ];

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

  services = {
    hydra = {
      enable = true;
      package = pkgs.hydra;
      hydraURL = "https://hydra.arm53.xyz";
      notificationSender = "hydra@arm53.xyz";
      listenHost = "localhost";
      smtpHost = "localhost";
      useSubstitutes = true;
      # extraConfig =
      #   /*
      #   xml
      #   */
      #   ''
      #     Include ${config.sops.secrets.hydra-gh-auth.path}
      #     max_unsupported_time = 30
      #     <githubstatus>
      #       jobs = .*
      #       useShortContext = true
      #     </githubstatus>
      #   '';
      extraEnv = {
        HYDRA_DISALLOW_UNFREE = "0";
      };
    };
    nginx.virtualHosts = {
      "hydra.arm53.xyz" = {
        forceSSL = true;
        useACMEHost = "hydra.arm53.xyz";
        locations = {
          "~* ^/shield/([^\\s]*)".return = "302 https://img.shields.io/endpoint?url=https://hydra.arm53.xyz/$1/shield";
          "/" = {
            proxyPass = "http://localhost:${toString config.services.hydra.port}";
            extraConfig = ''
              proxy_set_header X-Request-Base "https://hydra.arm53.xyz";
            '';
          };
        };
      };
    };
  };
  users.users = {
    hydra-queue-runner.extraGroups = [hydraGroup];
    hydra-www.extraGroups = [hydraGroup];
  };
  sops.secrets = {
    # hydra-gh-auth = {
    #   sopsFile = ../../secrets.yaml;
    #   owner = hydraUser;
    #   group = hydraGroup;
    #   mode = "0440";
    # };
    # nix-ssh-key = {
    #   sopsFile = ../../secrets.yaml;
    #   owner = hydraUser;
    #   group = hydraGroup;
    #   mode = "0440";
    # };
  };

  environment.persistence = {
    "/persist".directories = [
      "/var/lib/hydra"
      "/var/lib/postgresql"
    ];
  };
}

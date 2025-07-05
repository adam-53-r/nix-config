{
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  services.alloy = {
    enable = true;
  };
  environment.etc."alloy/config.alloy".source = ./config.alloy;

  systemd.services.alloy.serviceConfig.SupplementaryGroups = ifTheyExist [
    "nginx"
  ];
}

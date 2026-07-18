{config, ...}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  services.alloy = {
    enable = true;
  };

  environment.etc."alloy/config.alloy".source = ./config.alloy;

  # Only allow Mikrotik to send syslog to alloy
  networking.firewall.extraInputRules = "ip6 saddr { fd16:a5f8:258:2::1/128 } udp dport 51893 accept";

  systemd.services.alloy.serviceConfig.SupplementaryGroups = ifTheyExist [
    "nginx"
  ];
}

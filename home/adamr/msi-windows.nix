{lib, ...}: {
  imports = [
    ./global
    ./features/productivity
    ./features/pass
  ];
  home.persistence = lib.mkForce {};
  services.gpg-agent.enable = lib.mkForce false;
  nix = {
    settings = {
      extra-substituters = lib.mkForce [];
      extra-trusted-public-keys = lib.mkForce [];
    };
  };
}


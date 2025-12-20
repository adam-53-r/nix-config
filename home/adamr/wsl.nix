{lib, ...}: {
  imports = [
    ./global
    ./features/productivity
    ./features/pass
  ];

  disabledModules = [./features/cli/wine.nix];

  home.persistence = lib.mkForce {};

  gtk.enable = true;

  nix = {
    settings = {
      extra-substituters = lib.mkForce [];
      extra-trusted-public-keys = lib.mkForce [];
    };
  };

  programs.git = {
    settings.user = {
      name = lib.mkForce "Adam Rkouni (WSL NixOS)";
      signing.key = lib.mkForce "E11BFA7CD08E29E121814B554C9AF4FAC826B53E";
    };
    includes = [{path = "local.conf";}];
  };

  programs.ssh.includes = ["local.conf"];
}

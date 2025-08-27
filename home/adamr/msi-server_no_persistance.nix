{lib, ...}: {
  imports = [
    ./global
  ];
  home.persistence = lib.mkForce {};
}

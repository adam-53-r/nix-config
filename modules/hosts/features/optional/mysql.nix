# MariaDB with its state persisted.
{
  flake.nixosModules.optionalMysql = {pkgs, ...}: {
    key = "mynix#nixosModules.optionalMysql";

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    environment.persistence = {
      "/persist".directories = ["/var/lib/mysql"];
    };
  };
}

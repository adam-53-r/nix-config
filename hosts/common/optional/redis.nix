{
  pkgs,
  ...
}: {
  services.redis.servers = {
    
  };

  environment.persistence = {
    "/persist".directories = [ "/var/lib/mysql" ];
  };
}

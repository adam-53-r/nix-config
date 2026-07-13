{...}: {
  flake.nixosModules.globalAcme = {...}: {
    key = "mynix#nixosModules.globalAcme";
    security.acme = {
      defaults.email = "hi@arm53.xyz";
      acceptTerms = true;
    };

    environment.persistence = {
      "/persist".directories = ["/var/lib/acme"];
    };
  };
}

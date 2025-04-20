{
  # Enable acme for usage with nginx vhosts
  security.acme = {
    defaults.email = "hi@arm53.xyz";
    acceptTerms = true;
  };

  environment.persistence = {
    "/persist" = {
      directories = ["/var/lib/acme"];
    };
  };
}

# ACME / Let's Encrypt defaults for nginx vhosts, shared by every host.
# Ported from msi-server `common/global/acme.nix`. NOTE: for certificates to
# actually issue on the OCI host, a public DNS record must point at the VM and
# ports 80/443 must be reachable from the internet.
{...}: {
  flake.nixosModules.globalAcme = {...}: {
    security.acme = {
      defaults.email = "hi@arm53.xyz";
      acceptTerms = true;
    };

    environment.persistence = {
      "/persist".directories = ["/var/lib/acme"];
    };
  };
}

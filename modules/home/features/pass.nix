# pass + extensions, exposed over the freedesktop secret service API so GUI
# apps can use it as their keyring.
{
  flake.homeModules.homePass = {
    pkgs,
    config,
    ...
  }: {
    programs.password-store = {
      enable = true;
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      };
      package = pkgs.pass.withExtensions (p: [
        p.pass-otp
        p.pass-import
        p.pass-genphrase
      ]);
    };

    services.pass-secret-service = {
      enable = true;
      extraArgs = ["-e${config.programs.password-store.package}/bin/pass"];
    };

    home.persistence."/persist".directories = [".password-store"];
  };
}

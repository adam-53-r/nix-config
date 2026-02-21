{
  pkgs,
  config,
  ...
}: {
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
    };
    package = pkgs.pass.withExtensions (p: [
      p.pass-otp
      p.pass-import
      p.pass-genphrase
    ]);
  };

  services.pass-secret-service = {
    enable = true;
    # storePath = "${config.home.homeDirectory}/.password-store";
    extraArgs = ["-e${config.programs.password-store.package}/bin/pass"];
  };

  home.persistence = {
    "/persist".directories = [".password-store"];
  };
}

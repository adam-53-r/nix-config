{pkgs, config, ...}: {
  home.packages = with pkgs; [brave];
  home = {
    persistence = {
      # Not persisting is safer
      "/persist/${config.home.homeDirectory}".directories = [
        {
          directory = ".config/BraveSoftware";
          method = "bindfs";
        }
      ];
    };
  };
}

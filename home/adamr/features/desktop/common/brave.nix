{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [brave];
  home = {
    persistence = {
      # Not persisting is safer
      "/persist".directories = [
        {
          directory = ".config/BraveSoftware";
        }
      ];
    };
  };
}

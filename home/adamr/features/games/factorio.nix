{
  pkgs,
  config,
  ...
}: {
  home = {
    packages = [pkgs.factorio];
    persistence = {
      "/persist" = {
        # allowOther = true;
        directories = [
          {
            directory = ".factorio";
          }
        ];
      };
    };
  };
}

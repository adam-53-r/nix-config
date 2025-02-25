{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.wine];
}
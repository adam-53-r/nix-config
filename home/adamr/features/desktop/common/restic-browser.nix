{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [restic restic-browser];
}

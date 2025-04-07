 {
  pkgs,
  ...
}: {
  imports = [
    ./global
    ./features/desktop/cinnamon
    ./features/games
  ];
}
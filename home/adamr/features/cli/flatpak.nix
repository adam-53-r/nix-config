{
  config,
  pkgs,
  ...
}: {
  home.persistence."/persist".directories = [
    ".local/share/flatpak"
  ];
}

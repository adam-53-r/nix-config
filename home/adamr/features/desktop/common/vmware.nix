{
  pkgs,
  config,
  ...
}: {
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    "vmware"
    ".vmware"
  ];
}

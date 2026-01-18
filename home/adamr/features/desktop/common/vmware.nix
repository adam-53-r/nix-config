{
  pkgs,
  config,
  ...
}: {
  home.persistence."/persist".directories = [
    "vmware"
    ".vmware"
  ];
}

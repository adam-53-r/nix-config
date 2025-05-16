{config, ...}: {
  home.persistence."/persist/${config.home.homeDirectory}".directories = [
    "VirtualBox VMs"
    ".config/VirtualBox"
  ];
}

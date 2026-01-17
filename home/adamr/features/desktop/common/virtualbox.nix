{config, ...}: {
  home.persistence."/persist".directories = [
    "VirtualBox VMs"
    ".config/VirtualBox"
  ];
}

# Only persistence — VirtualBox itself comes from the system module.
{
  flake.homeModules.homeVirtualbox = {
    home.persistence."/persist".directories = [
      "VirtualBox VMs"
      ".config/VirtualBox"
    ];
  };
}

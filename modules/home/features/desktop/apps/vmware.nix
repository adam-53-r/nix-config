# Only the VM/config persistence — the vmware package itself is a system
# module concern (unfree kernel modules).
{
  flake.homeModules.homeVmware = {
    home.persistence."/persist".directories = [
      "vmware"
      ".vmware"
    ];
  };
}

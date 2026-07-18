{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.vmConfiguration = {
    pkgs,
    lib,
    ...
  }: {
    key = "mynix#nixosModules.vmConfiguration";
    imports = [
      self.nixosModules.globalDefaults
      self.nixosModules.vmHardware
      self.nixosModules.userAdamr
    ];

    networking.hostName = "vm";
    # Throwaway host: not enrolled in .sops.yaml, so it can't decrypt the
    # shared user-password secret (mirrors oci/wsl).
    disable-user-sops = true;

    environment.systemPackages = with pkgs; [
      vim
      neovim
      helix
    ];

    system.stateVersion = "26.05";
  };
}

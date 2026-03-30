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
    imports = [
      self.nixosModules.vmHardware
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    environment.systemPackages = with pkgs; [
      vim
      neovim
      helix
    ];

    users.users.nixos = {
      isNormalUser = true;
      group = "users";
      initialPassword = "Admin1234";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };
    users.users.root = {
      initialPassword = "Admin1234";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvzQgNgw4EvEdpACjxlxKAJJl2sa8bvohMkh4mKUqja cardno:31_859_120"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgSs2wJGphaoUPS+VAu0QTJfvQ1P99AIYSc94V9WIEV cardno:30_548_977"
      ];
    };

    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "without-password";
    };

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";
  };
}

{self, inputs, ...}: {
  flake.nixosModules.pcConfiguration = {pkgs, lib, ...}: {
    imports = [
      self.nixosModules.pcHardware
    ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    environment.systemPackages = with pkgs; [
      vim
      neovim
      firefox-bin
      helix
    ];

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";
  };
}

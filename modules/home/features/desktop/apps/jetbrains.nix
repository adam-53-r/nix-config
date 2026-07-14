# JetBrains IDEs from the stable channel (unstable rebuilds them too often).
{
  flake.homeModules.homeJetbrains = {pkgs, ...}: {
    home.packages = with pkgs.stable; [
      jetbrains.clion
      jetbrains.rust-rover
      jetbrains.webstorm
    ];
    home.persistence."/persist".directories = [".config/JetBrains"];
  };
}

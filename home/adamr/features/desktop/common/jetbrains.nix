{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.webstorm
  ];
}

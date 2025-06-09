{pkgs, ...}: {
  programs.ecryptfs.enable = true;
  boot.kernelModules = ["ecryptfs"];
  boot.supportedFilesystems = ["ecryptfs"];
  environment.systemPackages = [pkgs.ecryptfs];
}

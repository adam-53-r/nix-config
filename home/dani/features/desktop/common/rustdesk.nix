{pkgs, ...}: {
  home.packages = with pkgs.stable; [rustdesk];
}

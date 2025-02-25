{
  pkgs,
  config,
  ...
}: {
  home.packages = [pkgs.jira-cli-go];
}
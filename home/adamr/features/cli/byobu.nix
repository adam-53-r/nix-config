{
  pkgs,
  config,
  ...
}: {
  programs.tmux.enable = true;
  home.packages = [
    pkgs.byobu
  ];
  home.file = {
    ".config/byobu/backend".text = "BYOBU_BACKEND=tmux";
    ".config/byobu/keybindings.tmux".text = ''
      unbind-key -n C-a
      set -g prefix ^A
      set -g prefix2 F12
      bind a send-prefix
    '';
  };
}

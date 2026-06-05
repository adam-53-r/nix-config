{
  pkgs,
  config,
  ...
}: {
  environment.persistence = {
    "/persist".directories = [
      "/var/lib/private/ollama"
      # config.services.open-webui.stateDir
    ];
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    # loadModels = [
    #   "qwen3:8b"
    #   "llama3.3:8b"
    #   "gpt-oss:20b"  # if you've got the VRAM
    # ];
  };

  services.open-webui = {
    enable = true;
  };

  # services.searx = {
  #   enable = true;
  # };

  environment.systemPackages = with pkgs; [
    # openclaw
    claude-code-bin
    claude-mergetool
    claude-monitor
  ];
}

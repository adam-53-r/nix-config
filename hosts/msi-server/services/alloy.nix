{
  services.alloy = {
    enable = true;
  };
  environment.etc."alloy/config.alloy".source = ./alloy.yml;
}

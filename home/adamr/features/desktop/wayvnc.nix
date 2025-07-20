{
  services.wayvnc = {
    enable = true;
    autoStart = false;
    settings = {
      address = "127.0.0.1";
      port = 5901;
    };
  };
}

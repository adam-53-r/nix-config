{
  ...  
}: {
  services.sftpgo = {
    enable = true;
    settings = {
      httpd.bindings = [
        {
          port = 8080;
          address = "0.0.0.0";
          enable_web_client = true;
          enable_web_admin = true;
          enable_https = true;
          certificate_file = "/var/lib/sftpgo/certificate.pem";
          certificate_key_file = "/var/lib/sftpgo/privatekey.pem";
        }
      ];
      ftpd.bindings = [
        {
          port = 21;
          address = "0.0.0.0";
        }
      ];
    };
  };
  environment.persistence = {
    "/persist" = {
      directories = [
        {
          directory = "/var/lib/sftpgo";
          user = "sftpgo";
          group = "sftpgo";
        }
      ];
    };
  };
}
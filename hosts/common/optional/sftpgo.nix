{
  config,
  pkgs,
  ...  
}: let 
  certificate_file = "${config.services.sftpgo.dataDir}/certificate.pem";
  certificate_key_file = "${config.services.sftpgo.dataDir}/privatekey.pem";
in {
  services.sftpgo = {
    enable = true;
    settings = {
      data_provider = {
        users_base_dir = "/var/lib/sftpgo/data";
      };
      httpd.bindings = [
        {
          port = 8080;
          enable_web_client = true;
          enable_web_admin = true;
          enable_https = true;
          inherit certificate_file certificate_key_file;
        }
      ];
      sftpd.bindings = [
        {
          port = 2022;
        }
      ];
    };
  };

  # Generate self-signed SSL certificate in case there isn't one present
  systemd.services.sftpgo.preStart = ''
    # Make sure we don't write to stdout, since in case of
    # socket activation, it goes to the remote side (#19589).
    exec >&2
    if !([ -e ${certificate_file} ] && [ -e ${certificate_key_file} ]); then
      rm -f ${certificate_file} ${certificate_key_file}
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -keyout ${certificate_key_file} -out ${certificate_file} -sha256 -days 3650 -nodes -subj "/C=ES/CN=msi-server"
    fi
  '';

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

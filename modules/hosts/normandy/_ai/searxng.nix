# SearXNG as the search backend for open-webui and opencode. Localhost only.
{lib, ...}: {
  services.searx = {
    enable = true;
    settings = {
      general.instance_name = "normandy";
      server = {
        bind_address = "127.0.0.1";
        port = 8888;
        secret_key = "$SEARX_SECRET_KEY";
        public_instance = false;
      };
      # Both clients use the JSON API, which is off by default.
      search.formats = ["html" "json"];
    };
  };

  # The key only signs SearXNG's own tokens, so a fresh one each boot is
  # harmless here and keeps it out of sops.
  systemd.services.searx-init.script = lib.mkBefore ''
    export SEARX_SECRET_KEY=$(head -c 32 /dev/urandom | sha256sum | cut -d' ' -f1)
  '';
}

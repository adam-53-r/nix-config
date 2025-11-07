{
  services.loki = rec {
    enable = true;
    dataDir = "/DATA/msi-server/loki";
    configuration = {
      auth_enabled = false;
      server.log_level = "error";

      server.http_listen_port = 3100;
      server.grpc_listen_port = 9096;

      common = {
        ring = {
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "${dataDir}/data";
        storage.filesystem = {
          chunks_directory = "${dataDir}/data/chunks";
          rules_directory = "${dataDir}/data/rules";
        };
      };

      schema_config.configs = [
        {
          from = "2020-05-15";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];
      # pattern_ingester = {
      #   enabled = true;
      #   metric_aggregation.loki_address = "http://localhost:3100";
      # };
      # ruler.enable_api = true;
      frontend.encoding = "protobuf";
      # compactor = {
      #   working_directory = "/tmp/loki/retention";
      #   delete_request_store = "filesystem";
      #   retention_enabled = true;
      # };
    };
  };
}

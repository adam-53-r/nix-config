{
  services.alloy = {
    enable = true;
  };
  environment.etc."alloy/config.alloy".text = ''
    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }

    loki.source.journal "read"  {
      forward_to    = [loki.write.grafana_loki.receiver]
      relabel_rules = loki.relabel.journal.rules
      labels        = {component = "loki.source.journal"}
    }

    // local.file_match "local_files" {
    //    path_targets = [{"__path__" = "/var/log/test.log"}]
    //    sync_period = "5s"
    // }

    // loki.source.file "log_scrape" {
    //    targets    = local.file_match.local_files.targets
    //    forward_to = [loki.process.filter_logs.receiver]
    //    tail_from_end = true
    // }

    // loki.process "filter_logs" {
    //    stage.drop {
    //      source = ""
    //      expression  = ".*Connection closed by authenticating user root"
    //      drop_counter_reason = "noisy"
    //    }
    //    forward_to = [loki.write.grafana_loki.receiver]
    // }

    loki.write "grafana_loki" {
       endpoint {
          url = "http://localhost:3100/loki/api/v1/push"

          // basic_auth {
          //  username = "admin"
          //  password = "admin"
          // }
       }
    }

    // Enables the ability to view logs in the Alloy UI in realtime
    // livedebugging {
    //   enabled = true
    // }
  '';
}

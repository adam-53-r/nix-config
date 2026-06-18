hostname: {
  boot = {
    name = "BOOT";
    size = "1G";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
      mountOptions = ["umask=0077"];
    };
  };

  "${hostname}" = {
    size = "100%";
    content = {
      type = "btrfs";
      extraArgs = ["-f"]; # Override existing partition
      # Subvolumes must set a mountpoint in order to be mounted,
      # unless their parent is mounted
      subvolumes = {
        "/root" = {
          mountpoint = "/";
          mountOptions = ["compress=zstd" "nodiscard"];
        };
        "/root-blank" = {};
        "/nix" = {
          mountpoint = "/nix";
          mountOptions = ["compress=zstd" "noatime" "nodiscard"];
        };
        "/persist" = {
          mountpoint = "/persist";
          mountOptions = ["compress=zstd" "nodiscard"];
        };
        "/swap" = {
          mountpoint = "/swap";
          mountOptions = ["noatime" "nodiscard"];
        };
        "/snapshots" = {};
        "/snapshots/root" = {};
        "/snapshots/persist" = {};
      };
    };
  };
}

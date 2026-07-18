# Opt-in alternative to optionalQuietboot: plays a source video as the boot
# splash instead of the static spinner, via pkgs.plymouth-video-theme (see
# that package for how frame extraction works). Disabled by default and not
# wired into any host yet — set myPlymouthVideo.videoFile once a source video
# is chosen, or leave it null to boot a placeholder test pattern.
{
  flake.nixosModules.optionalQuietbootVideo = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.myPlymouthVideo;
  in {
    key = "mynix#nixosModules.optionalQuietbootVideo";

    options.myPlymouthVideo = {
      enable = lib.mkEnableOption "plymouth boot-video theme (frame-sequence playback of a video file)";

      videoFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Source video to convert into the boot animation. Leave null to build a placeholder SMPTE test-pattern clip.";
      };

      fps = lib.mkOption {
        type = lib.types.int;
        default = 24;
      };

      width = lib.mkOption {
        type = lib.types.int;
        default = 1920;
      };

      height = lib.mkOption {
        type = lib.types.int;
        default = 1080;
      };
    };

    config = lib.mkIf cfg.enable {
      console = {
        useXkbConfig = true;
        earlySetup = false;
      };

      boot = {
        plymouth = {
          enable = true;
          theme = "video-boot";
          themePackages = [
            (pkgs.plymouth-video-theme.override {
              video = cfg.videoFile;
              inherit (cfg) fps width height;
            })
          ];
        };
        kernelParams = [
          "quiet"
          "loglevel=3"
          "systemd.show_status=auto"
          "udev.log_level=3"
          "rd.udev.log_level=3"
          "vt.global_cursor_default=0"
        ];
        consoleLogLevel = 0;
        initrd.verbose = false;
        # Needed so plymouth covers the initrd stage too, not just after
        # switch-root, otherwise the video only starts partway through boot.
        initrd.systemd.enable = true;
      };
    };
  };
}

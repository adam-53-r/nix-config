# Plymouth has no video-container decoder — this converts a source video into
# a PNG frame sequence at build time (via ffmpeg) and drives it with a
# `script`-module plymouth theme, the same technique boot-splash "video"
# themes (Steam Deck included) actually use under the hood.
#
# `video = null` (the default) builds a placeholder SMPTE test-pattern clip
# instead, so the theme/module wiring can be built and smoke-tested before a
# real source video is chosen.
{
  stdenv,
  lib,
  ffmpeg,
  video ? null,
  name ? "video-boot",
  fps ? 24,
  durationSeconds ? 6,
  width ? 1920,
  height ? 1080,
}: let
  header = ''
    Window.SetBackgroundTopColor(0, 0, 0);
    Window.SetBackgroundBottomColor(0, 0, 0);

    fps = ${toString fps};
    screen_width = Window.GetWidth();
    screen_height = Window.GetHeight();

    frame_sprite = Sprite();
    frame_sprite.SetX(0);
    frame_sprite.SetY(0);
    frame_sprite.SetZ(10000);
  '';

  footer = ''
    fun display_frame(index) {
      img = frame_images[index];
      if (img) {
        scaled_img = img.Scale(screen_width, screen_height);
        frame_sprite.SetImage(scaled_img);
      }
    }

    display_frame(1);

    fun boot_progress_callback(duration, progress) {
      elapsed = duration * progress;
      idx = (Math.Int(elapsed * fps) % frame_count) + 1;
      display_frame(idx);
    }

    Plymouth.SetBootProgressFunction(boot_progress_callback);
  '';

  extractFrames =
    if video != null
    then ''
      ffmpeg -y -i ${lib.escapeShellArg (toString video)} \
        -vf "fps=${toString fps},scale=${toString width}:${toString height}:force_original_aspect_ratio=decrease,pad=${toString width}:${toString height}:(ow-iw)/2:(oh-ih)/2" \
        frames/frame-%04d.png
    ''
    else ''
      ffmpeg -y -f lavfi \
        -i "smptebars=size=${toString width}x${toString height}:rate=${toString fps}:duration=${toString durationSeconds}" \
        frames/frame-%04d.png
    '';
in
  stdenv.mkDerivation {
    pname = "plymouth-${name}";
    version = "1.0";

    dontUnpack = true;
    nativeBuildInputs = [ffmpeg];

    buildPhase = ''
      runHook preBuild

      mkdir -p frames
      ${extractFrames}

      frame_count=$(find frames -name 'frame-*.png' | wc -l)
      if [ "$frame_count" -eq 0 ]; then
        echo "plymouth-video-theme: ffmpeg produced no frames" >&2
        exit 1
      fi

      {
        printf '%s\n' ${lib.escapeShellArg header}
        i=1
        for f in $(find frames -name 'frame-*.png' | sort); do
          printf 'frame_images[%d] = Image("%s");\n' "$i" "$(basename "$f")"
          i=$((i + 1))
        done
        printf 'frame_count = %d;\n' "$frame_count"
        printf '%s\n' ${lib.escapeShellArg footer}
      } > theme.script

      cat > theme.plymouth <<PLYMOUTH
      [Plymouth Theme]
      Name=${name}
      Description=Auto-generated video-frame-sequence theme
      ModuleName=script

      [script]
      ImageDir=/etc/plymouth/themes/${name}
      ScriptFile=/etc/plymouth/themes/${name}/theme.script
      PLYMOUTH

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plymouth/themes/${name}
      cp frames/*.png theme.script theme.plymouth $out/share/plymouth/themes/${name}/
      runHook postInstall
    '';

    meta.platforms = lib.platforms.linux;
  }

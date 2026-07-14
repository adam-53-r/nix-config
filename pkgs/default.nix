{pkgs ? import <nixpkgs> {}, ...}: {
  # Personal scripts
  minicava = pkgs.callPackage ./minicava {};
  pass-wofi = pkgs.callPackage ./pass-wofi {};
  xpo = pkgs.callPackage ./xpo {};

  # My slightly customized plymouth theme, just makes the blue outline white
  plymouth-spinner-monochrome = pkgs.callPackage ./plymouth-spinner-monochrome {};
  # Plays a source video as a boot splash (converted to a PNG frame sequence
  # at build time via ffmpeg, since plymouth can't decode video containers).
  plymouth-video-theme = pkgs.callPackage ./plymouth-video-theme {};
}

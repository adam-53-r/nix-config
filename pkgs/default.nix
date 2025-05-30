{pkgs ? import <nixpkgs> {}, ...}: {
  # Packages with an actual source
  lyrics = pkgs.python3Packages.callPackage ./lyrics {};

  # Personal scripts
  minicava = pkgs.callPackage ./minicava {};
  pass-wofi = pkgs.callPackage ./pass-wofi {};
  xpo = pkgs.callPackage ./xpo {};

  # My slightly customized plymouth theme, just makes the blue outline white
  plymouth-spinner-monochrome = pkgs.callPackage ./plymouth-spinner-monochrome {};
}

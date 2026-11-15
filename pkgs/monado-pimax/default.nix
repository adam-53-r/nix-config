# Monado built from the fork that carries the Pimax P3C driver (Crystal Light,
# Crystal Super, Dream Air).
# https://vronlinux.org/docs/hardware/pimax/p3c/
{
  monado,
  fetchFromGitLab,
  rustPlatform,
  cargo,
  rustc,
  corrosion,
  ceres-solver,
}:
monado.overrideAttrs (old: rec {
  pname = "monado-pimax";
  version = "25.1.0-unstable-2026-11-09";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "ultradev";
    repo = "monado";
    # branch pimax-p3c
    rev = "044dfcf85bd4f2f27e7c0dd195bac4b494f29b71";
    hash = "sha256-G3OOyHlb3sUe7RpYmcYB4TxQxzxpDBm8AkwkdA+MFFI=";
  };

  # The branch already has the fix nixpkgs backports.
  patches = [];

  # The driver is a Rust crate that cmake builds through corrosion.
  cargoRoot = "src/xrt/drivers/pimax_p3c";
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    sourceRoot = "${src.name}/${cargoRoot}";
    hash = "sha256-1ENXqt86rjI6BzaRQ08mqeNfgo0zTsr9xs3DqPrZ4rI=";
  };

  nativeBuildInputs =
    old.nativeBuildInputs
    ++ [
      cargo
      rustc
      rustPlatform.cargoSetupHook
      rustPlatform.bindgenHook
    ];

  buildInputs =
    old.buildInputs
    ++ [
      corrosion
      ceres-solver
    ];
})

{
  lib,
  stdenv,
  makeWrapper,
  alacritty,
  coreutils,
  fzf,
  helix,
  jq,
  rbw,
  wl-clipboard,
  wtype,
}:
stdenv.mkDerivation {
  name = "rbw-picker";
  version = "1.0";
  src = ./.;

  nativeBuildInputs = [makeWrapper];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    install -Dm 0644 picker.jq $out/share/rbw-picker/picker.jq
    install -Dm 0755 rbw-picker.sh $out/bin/rbw-picker
    substituteInPlace $out/bin/rbw-picker --subst-var out
    wrapProgram $out/bin/rbw-picker --prefix PATH ':' \
      "${
      lib.makeBinPath [
        alacritty
        coreutils
        fzf
        helix
        jq
        rbw
        wl-clipboard
        wtype
      ]
    }"
  '';

  meta = {
    description = "A read-only fzf picker for rbw";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "rbw-picker";
  };
}

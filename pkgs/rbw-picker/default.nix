{
  lib,
  stdenv,
  makeWrapper,
  alacritty,
  bitwarden-cli,
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
        bitwarden-cli
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
    description = "An fzf picker for rbw, editing through the bitwarden CLI";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "rbw-picker";
  };
}

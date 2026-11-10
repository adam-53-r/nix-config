{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShellNoCC {
      # decrypt.sh calls sops while Nix evaluates, so it has to be on PATH.
      packages = [pkgs.sops];

      NIX_CONFIG = "allow-unsafe-native-code-during-evaluation = true";

      # Only hop into fish when interactive, so `nix develop -c <cmd>` still runs <cmd>.
      shellHook = ''
        if [[ $- == *i* ]]; then
          exec fish
        fi
      '';
    };
  };
}

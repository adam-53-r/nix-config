{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShellNoCC {
      shellHook = ''
        export NIX_CONFIG="
          allow-unsafe-native-code-during-evaluation = true
        "
        exec fish
      '';
    };
  };
}
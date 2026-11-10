{exec, ...}: let
  assertMsg = pred: msg: pred || builtins.throw msg;
in {
  importEncrypted = nixFile:
    assert assertMsg (builtins.isPath nixFile)
      "The file to decrypt must be given as a path to prevent impurity.";
    # assert assertMsg (builtins.hasSuffix ".nix.sops" nixFile)
    #   "The content of the decrypted file must be a nix expression and should therefore end in .nix.sops";
      exec ([./decrypt.sh nixFile]);
}

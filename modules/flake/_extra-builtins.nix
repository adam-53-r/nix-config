# Usage: (import ./_extra-builtins.nix builtins).importEncrypted ./foo.nix.sops
{
  # A default is only evaluated when it's used, so outside the devshell the
  # import still works and only an actual decryption fails, with this message.
  exec ? throw "builtins.exec is missing, run this inside `nix develop` to decrypt *.nix.sops files",
  ...
}: let
  assertMsg = pred: msg: pred || throw msg;
in {
  # Takes a path literal, since that comes from the flake source while a
  # string could point anywhere on the machine.
  importEncrypted = nixFile:
    assert assertMsg (builtins.isPath nixFile)
    "importEncrypted: expected a path, got a ${builtins.typeOf nixFile}";
    assert assertMsg (builtins.match ".*\\.nix\\.sops" (toString nixFile) != null)
    "importEncrypted: ${toString nixFile} should end in .nix.sops";
      exec [./decrypt.sh nixFile];
}

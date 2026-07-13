# sops-nix secret decryption keyed on the SSH host key, shared by every host.
# No secrets are defined here; hosts that need secrets add `sops.secrets.*`
# themselves. The age key is derived from the ed25519 SSH host key configured
# in globalOpenssh.
{inputs, ...}: {
  flake.nixosModules.globalSops = {config, ...}: let
    isEd25519 = k: k.type == "ed25519";
    getKeyPath = k: k.path;
    keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
  in {
    key = "mynix#nixosModules.globalSops";
    imports = [inputs.sops-nix.nixosModules.sops];

    sops.age.sshKeyPaths = map getKeyPath keys;
  };
}

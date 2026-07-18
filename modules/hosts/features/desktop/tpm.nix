# TPM2 support (pkcs11 + tpm-fido's uhid access).
{
  flake.nixosModules.desktopTpm = {config, ...}: {
    key = "mynix#nixosModules.desktopTpm";

    security.tpm2 = {
      enable = true;
      pkcs11.enable = true;
    };
    boot.kernelModules = ["uhid"];
    # Needed for tpm-fido
    services.udev.extraRules = ''
      KERNEL=="uhid", SUBSYSTEM=="misc", GROUP="${config.security.tpm2.tssGroup}", MODE="0660"
    '';
  };
}

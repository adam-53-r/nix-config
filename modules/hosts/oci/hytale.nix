# Hytale dedicated server on the oci host, alongside the existing Minecraft
# modpack server (oci is VM.Standard.A1.Flex: 4 OCPUs / 24GB RAM, comfortable
# headroom for both).
#
# The Hytale downloader CLI has no arm64 build (only
# hytale-downloader-linux-amd64 exists) - the live server itself is plain
# Java and runs natively on aarch64, but the update-check/download step needs
# to run the amd64 downloader under emulation. boot.binfmt.emulatedSystems
# below registers qemu-user for that; combined with nix-ld (already enabled
# globally via globalDefaults) supplying the missing FHS dynamic linker, this
# is the same workaround the wider Hytale-on-ARM community (Raspberry Pi,
# Ampere hosts) uses.
#
# services.hytale-server does NOT bootstrap credentials itself: before the
# nightly update timer can do anything, hytale-downloader-linux-amd64 and a
# .hytale-downloader-credentials.json (from its OAuth device-flow login) must
# be placed by hand under ${dataDir}/downloader/.
{self, ...}: {
  flake.nixosModules.ociHytale = {...}: {
    key = "mynix#nixosModules.ociHytale";
    imports = [
      self.nixosModules.hytaleServer
    ];

    boot.binfmt.emulatedSystems = ["x86_64-linux"];

    services.hytale-server = {
      enable = true;
      dataDir = "/srv/hytale";
      openFirewall = true;
    };
  };
}

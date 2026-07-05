# "Minecraft Extremo 2" modpack server (Forge 1.18.2-40.3.0) on the oci host.
#
# nix-minecraft only packages vanilla/fabric/quilt/paper/purpur/velocity/
# neoforge - classic Forge is not covered, so the dedicated-server jar is
# built by hand below. Unlike NeoForge's installer, the Forge 1.18.2-40.3.0
# installer has no pure/offline install mode: it unconditionally makes a
# network call (downloading Mojang mappings) mid-install regardless of what's
# already on disk. That rules out a fully pure `fetchurl`-per-library lock, so
# the install step is a fixed-output derivation (FOD) instead - network
# access is permitted during the build, and reproducibility is guaranteed by
# pinning `outputHash` rather than the dependency closure.
{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.ociMinecraft = {
    pkgs,
    lib,
    ...
  }: let
    forgeInstaller = pkgs.fetchurl {
      url = "https://maven.minecraftforge.net/net/minecraftforge/forge/1.18.2-40.3.0/forge-1.18.2-40.3.0-installer.jar";
      hash = "sha256-lDTCl5BQTc0RzpfLMN2IkbSxiEiYI1e8G1q/p5+5UQM=";
    };

    # Stage 1 (FOD): run the impure installer and capture only the resulting
    # libraries/ + user_jvm_args.txt, untouched (still referencing relative
    # "libraries/" paths). No store-path references - not even
    # self-references, which FODs also reject - are embedded in this output.
    forgeLibraries = pkgs.stdenvNoCC.mkDerivation {
      pname = "minecraft-forge-server-libraries";
      version = "1.18.2-40.3.0";
      dontUnpack = true;
      dontConfigure = true;
      dontFixup = true;
      nativeBuildInputs = [pkgs.jdk17_headless];
      buildPhase = ''
        runHook preBuild
        export HOME=$TMPDIR
        java -jar ${forgeInstaller} --installServer .
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r libraries user_jvm_args.txt $out/
        runHook postInstall
      '';
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = "sha256-85EVx4ghH83xGIEnPdAZ2w13RA0gPhAZRhzqAlBoDJ0=";
    };

    # Stage 2 (normal derivation): rewrite the relative library paths to this
    # derivation's own absolute $out, and wrap with a launcher script.
    # jvmOpts (nix-minecraft appends them after the wrapped executable) must
    # land BEFORE unix_args.txt's mainclass, since Java treats every token
    # after a mainclass as a program argument regardless of which @file it
    # came from - a plain `makeWrapper --append-flags` would silently drop
    # heap-size flags as bogus Forge args.
    forgeServer = pkgs.stdenvNoCC.mkDerivation {
      pname = "minecraft-forge-server";
      version = "1.18.2-40.3.0";
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        cp -r ${forgeLibraries}/libraries $out/libraries
        chmod -R u+w $out/libraries
        args="$out/libraries/net/minecraftforge/forge/1.18.2-40.3.0/unix_args.txt"
        substituteInPlace "$args" \
          --replace-fail "-DlibraryDirectory=libraries" "-DlibraryDirectory=$out/libraries" \
          --replace-fail "libraries/" "$out/libraries/"
        cat > $out/bin/minecraft-server <<SCRIPT
        #!/bin/sh
        exec ${pkgs.jdk17_headless}/bin/java @${forgeLibraries}/user_jvm_args.txt "\$@" @$args
        SCRIPT
        chmod +x $out/bin/minecraft-server
        runHook postInstall
      '';
      meta = {
        description = "Minecraft Forge 1.18.2-40.3.0 dedicated server";
        mainProgram = "minecraft-server";
      };
    };

    # The modpack's server pack (mods/config), pinned by content hash from
    # CurseForge's CDN. Verified to be reproducible: the hash matches whether
    # fetched fresh or hashed from a manual download. This version's zip has
    # no top-level defaultconfigs/ directory.
    modpackZip = pkgs.fetchurl {
      url = "https://mediafilez.forgecdn.net/files/6525/852/Minecraft%20Extremo%202%20%28Server%20Pack%29%20-%20MC%201.18.2%20-%209.0.0.zip";
      hash = "sha256-v/QJILdeNRuBVc7ge0ElAnGJfLZ7fvq4c1uAEvSqhHg=";
    };

    modpack = pkgs.runCommand "minecraft-extremo-2-modpack" {nativeBuildInputs = [pkgs.unzip];} ''
      mkdir -p $out
      unzip -q ${modpackZip} 'mods/*' 'config/*' -d $out
    '';

    # Forge/FML and mods rewrite their own files under config/ at runtime
    # (e.g. journeymap/voicechat migrate their configs on first boot).
    # nix-minecraft's own symlinks/files handling unconditionally re-links or
    # re-copies every managed entry from the Nix store on EVERY restart
    # (backing up whatever was there to *.bak, but never restoring it) - so
    # letting it manage "config" would silently discard any such runtime
    # writes on every restart. Instead, seed config from the modpack only if
    # it doesn't already exist (first boot ever), via our own ExecStartPre
    # entry that's independent of nix-minecraft's own tracking file - so
    # ExecStopPost's cleanup (which only deletes what nix-minecraft itself
    # created) leaves it alone too. After that it's just an ordinary
    # writable dataDir directory that persists indefinitely. To pick up a
    # modpack update, manually remove/rename the on-disk config/ dir on the
    # host and restart.
    seedConfig = pkgs.writeShellApplication {
      name = "minecraft-server-extremo-seed-config";
      text = ''
        if [ ! -e config ]; then
          cp -r --dereference ${modpack}/config -T config
          chmod -R u+w config
        fi
      '';
    };
  in {
    imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];
    nixpkgs.overlays = [inputs.nix-minecraft.overlays.default];

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = true;

      servers.extremo = {
        enable = true;
        package = forgeServer;
        # Matches the modpack author's own recommended sizing (variables.txt).
        jvmOpts = "-Xms4G -Xmx4G";

        symlinks = {
          "mods" = "${modpack}/mods";
        };

        serverProperties = {
          motd = "Minecraft Extremo 2";
          difficulty = "normal";
          max-players = 10;
          # No secrets infra on oci yet (disable-user-sops); keep RCON off so
          # nix-minecraft doesn't open an unauthenticated management port.
          enable-rcon = false;
        };
      };
    };

    # List-typed so it concatenates with nix-minecraft's own ExecStartPre
    # (a plain string) instead of conflicting - see seedConfig's comment.
    systemd.services."minecraft-server-extremo".serviceConfig.ExecStartPre = [
      (lib.getExe seedConfig)
    ];
  };
}

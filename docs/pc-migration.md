# pc migration: main → dendritic-setup

Plan + findings for migrating the `pc` desktop host (live daily driver, Hyprland/uwsm)
from the traditional `main` layout to the dendritic flake-parts layout, adopting the
conventions proven in worknix.

## Findings on the live desktop (main) — bugs to fix during the port

1. **waypipe-client.service fails every login** — races uwsm's env export
   (`WAYLAND_DISPLAY` not yet in the systemd user environment when
   `graphical-session.target` units start) and has no recovery. HM's waybar survives
   the same race via `ConditionEnvironment=WAYLAND_DISPLAY` + `Restart=on-failure` +
   `After=graphical-session.target`. Fix: same stanza on both waypipe units.
2. **xsettingsd.service fails** — enabled in `gtk.nix` with the `settings` block left
   as a TODO, so no config file is ever generated and the daemon exits. Fix: generate
   settings from the gtk theme/icon config (Net/ThemeName, Net/IconThemeName).
3. **`common-cpu-intel` imported on an AMD machine** (`hosts/pc/hardware-configuration.nix`
   sets `hardware.cpu.amd.updateMicrocode` + amdgpu). Fix: `common-cpu-amd` (+
   `common-gpu-amd`).
4. **nixGL wrapping on NixOS** — `config.lib.nixGL.wrap` around hyprland/waypipe is at
   best identity on NixOS (nixGL only configured on electra, a non-NixOS host). Drop.
5. **Two hyprland builds** — HM overrides `wayland.windowManager.hyprland.package`
   while the session actually launches the system `programs.hyprland` package via
   uwsm/SDDM; hyprctl/compositor can drift. Fix: HM `package = null` (config only),
   system owns the compositor.
6. **`remoteColorschemes` evaluates every host's full HM config** to color remote
   window borders — huge eval cost for a cosmetic, and depends on the `outputs`
   specialArg that dendritic doesn't pass. Drop.
7. **tlp + powertop on a desktop PC** — laptop tooling; powertop's autotune is why USB
   autosuspend fights (`USB_AUTOSUSPEND=0`, `usbcore.autosuspend=-1` were countermeasures).
   Drop tlp/powertop/x11-no-suspend on pc; keep power-profiles-daemon off only if
   something needs it.
8. **`displayManager.startx.enable` leftover** in cinnamon module alongside SDDM. Drop.
9. **Dead config**: hyprbars.nix fully commented; HM hyprland `systemd.extraCommands`
   while `systemd.enable = false`. Drop both.
10. **NUT ups misconfig** — `sops.secrets."nut/nut-admin"` is declared but the nut
    users/monitor actually use `adamr-wg-password` (copy-paste). Point NUT at its own
    secret.
11. **Portal config** — `xdg.portal.config.hyprland.default = ["wlr" "gtk"]` while
    xdg-desktop-portal-hyprland is running; wlr portal is redundant (no window
    picker). Use `["hyprland" "gtk"]`, drop the wlr portal from extraPortals.
12. `nix-colors` input only used for one hex→RGB helper in waybar → inline it.
    `nix-gaming` (star-citizen) and `firefox-addons` are not imported anywhere live →
    don't port the inputs.

## Conventions adopted from worknix

- Every named module carries `key = "mynix#nixosModules.<Name>"` (dedupe across
  import paths). `flake.homeModules` is declared once with an `apply` wrapper that
  injects `key`/`_file` automatically (crib `modules/flake/options.nix`).
- Underscore-prefixed files (`_hardware.nix`, `_disko.nix`, …) are skipped by
  import-tree: plain NixOS modules for host-private config, imported directly by the
  host's `default.nix`.
- Composite aggregates: `globalDefaults` (exists), new `desktopBase` for physical
  workstations.
- Flake-level plumbing under `modules/flake/`: `parts.nix`, `options.nix`,
  `overlays.nix` (flake-inputs alias overlay, additions from `pkgs/`), `packages.nix`
  (perSystem packages/devshell/formatter).
- Naming by directory: `modules/hosts/features/optional/docker.nix` → `optionalDocker`,
  `modules/hosts/features/desktop/keyd.nix` → `desktopKeyd`, etc.

## Phases

1. **Flake scaffolding**: move `modules/parts.nix`/`modules/home/options.nix` to
   `modules/flake/`, add auto-key wrapper, add `themes` input, port `overlays/` +
   `pkgs/` (pass-wofi, minicava) wiring, add `key` to existing nixos modules.
2. **Home option modules** (port from worknix, already dendritic):
   colors/fonts/monitors/wallpaper/xpo/pass-secret-service → `modules/home/options/`.
3. **System desktop modules** → `modules/hosts/features/desktop/`: sddm(+astronaut
   theme module), hyprland(uwsm), cinnamon (fallback session), pipewire, printing,
   keymap, keyd, yubikey/u2f/pcscd, tpm, pass-secret-service, steam-hardware,
   gamemode, kdeconnect ports, upower, networking(NetworkManager) → aggregate
   `desktopBase`. Optionals: steam, libvirtd, docker, wireshark, gns3(+server),
   persist-backup, flatpak.
4. **pc host**: `modules/hosts/pc/_hardware.nix` (faithful port: disko partitions,
   btrfs+luks+ephemeral root, limine+secure-boot+sbctl, snapshots/snapper, amdgpu,
   lact, swapfile, Windows boot entry — must reproduce the live disk layout exactly),
   `default.nix` (wireguard→msi-server, restic persist backup, NUT ups, ollama/open-webui,
   openrgb, qmk/vial udev, resolved, binfmt, xanmod), secrets.json + common secrets +
   `.sops.yaml`.
5. **Home desktop features** → `modules/home/features/desktop/`: wayland-wm set
   (waybar, wofi, mako, swaylock/idle, gammastep, cliphist, swayosd, waypipe(fixed),
   alacritty, qutebrowser, imv), hyprland (settings/binds/hypridle/hyprpaper),
   cinnamon, gtk(+xsettingsd fixed)/qt/fonts, the app modules pc actually uses,
   games (steam/prism/mangohud), productivity, pass, helix, wayvnc.
6. **Profile**: `adamr@pc` = adamrHome + desktop features + monitors/wallpaper +
   persistence; wire `userAdamr` into pcConfiguration.
7. **Validation**: `nix eval .#nixosConfigurations.pc.config.system.build.toplevel.drvPath`;
   diff `fileSystems`/`boot.initrd`/luks/disko output against the main-branch build of
   pc (must match — live machine); full `nix build` of the toplevel (x86_64, buildable
   locally). No switch without explicit go-ahead.

## Non-goals (later)

- msi-nixos laptop, msi-server (+services), wsl host — after pc proves the pattern.
- Patching `main` itself: fixes land in the dendritic port; cherry-pick back on request.

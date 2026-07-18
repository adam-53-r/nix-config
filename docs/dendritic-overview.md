# dendritic-setup: structure & patterns

Quick orientation for the `dendritic-setup` branch. For the migration-era
decisions and bugs found/fixed along the way, `git log`/`git diff` against
`main` is now the record (the old planning doc, `docs/pc-migration.md`, has
been retired now that all hosts are ported).

## The core idea

`flake.nix` is tiny:

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
```

`import-tree` recursively imports **every `.nix` file** under `modules/` as a
flake-parts module, except files/dirs starting with `_` (those are plain
NixOS modules meant to be imported manually — see below). There is no central
registry to edit: drop a file anywhere under `modules/`, it's live.

Every file follows one of two shapes:

```nix
# a flake-parts module contributing a reusable NixOS profile
{self, inputs, ...}: {
  flake.nixosModules.fooBar = {pkgs, lib, config, ...}: {
    key = "mynix#nixosModules.fooBar";
    # ...actual NixOS module config...
  };
}
```

```nix
# a flake-parts module contributing a reusable home-manager profile
{self, ...}: {
  flake.homeModules.someProfile = {pkgs, lib, config, ...}: {
    # ...actual HM module config...
  };
}
```

Composition is *always* via `self.nixosModules.<name>` / `self.homeModules.<name>`
in an `imports = [...]` list — never relative file imports between profiles.

## Two critical wiring quirks

1. **Inner NixOS modules don't get `self`/`inputs`.** `nixosSystem` is called
   in `modules/hosts/default.nix` with no `specialArgs`. The outer flake-parts
   function (`{self, inputs, ...}: ...`) captures them in closure instead —
   that's why every nixosModules file starts with `{self, inputs, ...}:` on
   the *outside* and the inner module only asks for `pkgs, lib, config, ...`.
   Putting `inputs` in the inner module's args causes infinite recursion.
2. **Inner home-manager modules DO get `inputs`/`self`.** `globalHomeManager`
   wires HM with `extraSpecialArgs = {inherit inputs self;}`, so home modules
   can ask for them directly in their inner args.

`flake.nixosModules` is a flake-parts built-in (mergeable attrset). `flake.homeModules`
is not — it's declared once in `modules/flake/options.nix`, which also
auto-injects a `key`/`_file` on every entry so duplicate imports of the same
profile don't collide.

Every `nixosModules` entry needs an explicit `key = "mynix#nixosModules.<Name>";`
line (dedup marker, since anonymous inline modules don't merge safely when
imported twice through different paths).

## Repo layout

```
flake.nix                    inputs + the one-line mkFlake/import-tree call
modules/
  flake/                     flake-parts plumbing: systems list, the
                              homeModules option, overlays output, packages
                              output (alejandra formatter, pkgs/*)
  nixos/                     small reusable NixOS option modules
                              (sddm-astronaut-theme, hytale-server, ...)
  home/
    options/                 bare option declarations shared across profiles
                              (colors, fonts, monitors, wallpaper, xpo, ...)
    features/                composable HM profiles, one concern each
                              (ssh, gpg, gh, pass, productivity, games, helix,
                              impermanence, desktop/*)
    cli-base.nix              -> cliBase: shell+tools+git, safe for any user
    cli-workstation.nix        -> cliWorkstation: extra CLI for GUI hosts
    adamr/                    adamr's identity + per-host home profiles
                              ("adamr@<hostname>")
  hosts/
    default.nix               the ONLY place nixosSystem is called, once per
                              host, wiring self.nixosModules.<x>Configuration
    install-iso.nix           perSystem package `install-iso`: bootable
                              install-media ISO, not a real host (no
                              nixosConfigurations entry)
    common/
      global/                 globalDefaults aggregate + its pieces (nix,
                              openssh, fish, sops, persistence, tailscale, ...)
      users/                  userAdamr account module + shared secrets
    features/
      desktop/                desktopBase aggregate (sddm, hyprland,
                              cinnamon, networking, yubikey, tpm, ...)
      optional/               opt-in host features (docker, libvirtd, nginx,
                              disko-btrfs, steam, snapshots, ...)
    pc/, msi-nixos/, msi-server/, oci/, vm/, wsl/
                              one dir per host; default.nix is the flake
                              module, "_"-prefixed files (_hardware.nix,
                              _services/, _ai.nix, _ups.nix) are plain NixOS
                              modules import-tree skips, imported by that
                              host's default.nix directly.
  deploy.nix                 deploy-rs targets (`flake.deploy.nodes.<host>`),
                              currently `pc` and `oci`
overlays/                     nixpkgs overlays (flake-inputs alias, stable
                              channel, custom package patches)
pkgs/                         custom package derivations
docs/                         dendritic-overview.md (this file), disk-resize.md
```

### Why the `_`-prefix convention

import-tree would otherwise try to auto-import *every* `.nix` file as a
flake-parts module — including host-private plumbing like `_hardware.nix`
(hardware config) or a service directory's `_services/default.nix`. Those
aren't meant to be reusable `self.nixosModules.*` profiles, just plain NixOS
modules scoped to one host. Prefixing the file or directory with `_` tells
import-tree to skip it; the owning host's `default.nix` imports it by
relative path instead (`./_hardware.nix`, `./_services`).

## Hosts (as of this writing)

| Host | Purpose | Notes |
|---|---|---|
| `pc` | desktop, **live/deployed** | AMD, Hyprland+uwsm, LUKS+fido2, ephemeral btrfs, secure boot |
| `msi-nixos` | laptop | Intel+Nvidia PRIME (sync/offload specialisation), GRUB cryptodisk, TLP |
| `msi-server` | home server | headless, full self-hosted service stack, servers-vlan bridge |
| `oci` | Oracle free-tier VM | aarch64, disko image build, serial console |
| `vm` | test VM | minimal, for `nix eval`/quick checks |
| `wsl` | WSL2 NixOS | no disk/persistence concerns, work identity |

Only `pc` has actually been switched to on real hardware. The rest evaluate
cleanly (`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`)
but haven't been built/deployed from this branch yet.

## Aggregates worth knowing

These are the "profile" modules that pull everything else together — read
these first when tracing what a host actually gets:

- `globalDefaults` (`modules/hosts/common/global/default.nix`) — baseline
  every host imports: nix settings, openssh, fish, sops, persistence,
  tailscale, auto-upgrade, overlays applied here.
- `desktopBase` (`modules/hosts/features/desktop/default.nix`) — globalDefaults
  + the whole desktop stack (sddm, hyprland, cinnamon fallback, pipewire,
  printing, networking, keyd, yubikey, tpm, kdeconnect, pass). Used by `pc`
  and `msi-nixos`.
- `diskoBtrfs` (`modules/hosts/features/optional/disko-btrfs.nix`) — btrfs +
  ephemeral-root rollback + optional LUKS, parameterized by hostname.
- `adamrHome` (`modules/home/adamr/default.nix`) — cliBase + gpg/ssh/gh +
  adamr's git identity, host-agnostic. Every `adamr@<host>` profile builds on
  this.
- `homeTheming` (`modules/home/features/desktop/theming.nix`) — dark/light
  HM specialisations + the `colorscheme` options (fed by `config.wallpaper`
  via the `themes` flake input).

## Secrets

sops-nix, age host keys + PGP yubikeys. `.sops.yaml` at the repo root has
`creation_rules` keyed by path regex — one rule per host's `secrets.json`
under its `modules/hosts/<host>/` dir, plus a shared rule for
`modules/hosts/common/users/secrets.json`. Each host's NixOS module wires
`sops.secrets` pointing at its `./secrets.json`.

## Validating without hardware

Can't build aarch64 (`oci`) locally, and building the desktop hosts fully is
slow — for a quick correctness check, evaluate the toplevel derivation path
for each host:

```sh
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

This catches option-type errors, missing `self.nixosModules.*` references,
infinite recursion, etc. without building anything. Untracked new files are
invisible to the flake until `git add`ed (Nix flakes only see the git index).

Format with `nix run nixpkgs#alejandra -- <files>` (2-space indent) before
committing.

## Where to look for "why", not just "what"

The phase-by-phase migration log that used to live at `docs/pc-migration.md`
has been retired now that every host (`pc`, `msi-nixos`, `msi-server`, `oci`,
`vm`, `wsl`) is ported and evaluates clean — its "non-goals: later" section
was written when only `pc` was in scope and no longer reflects reality. For
the "why" behind a specific decision or bug fixed during the port (waypipe's
login race, the xsettingsd crash, the wrong CPU vendor module, NUT using the
wrong secret, etc.), `git log`/`git diff` against `main` on the relevant path
is now the record — most fixes landed as their own commit.

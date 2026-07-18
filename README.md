[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
[![flake-parts](https://img.shields.io/static/v1?label=&message=flake-parts&color=5277C3&logo=nixos&logoColor=white)](https://flake.parts)
[![dendritic pattern](https://img.shields.io/static/v1?label=&message=dendritic%20pattern&color=7EBAE4)](https://github.com/mightyiam/dendritic)

# mynix

My personal NixOS + home-manager configuration — desktop, laptop, home server
and a couple of VMs, all wired through one flake using the **dendritic
pattern**: every `.nix` file under `modules/` is its own self-contained
flake-parts module, auto-discovered by [`import-tree`][import-tree]. No
central `imports = [...]` list to keep in sync — drop a file anywhere under
`modules/`, it's live.

> [!IMPORTANT]
> Originally forked from [Misterio77's config](https://github.com/Misterio77/nix-config),
> which is still very much worth checking out — along with all his other
> great work. Looking for something simpler to start from? Try his
> [starter config][nix-starter-config] instead.

> [!NOTE]
> See [`docs/dendritic-overview.md`](docs/dendritic-overview.md)
> for the conventions and wiring quirks.

## Highlights

- 🌿 **Dendritic layout** — every file *is* a flake-parts module; no central
  module registry
- 🖥️ **Six NixOS configurations** spanning desktop, laptop, headless server,
  cloud VM, and disposable test/WSL VMs
- 🧩 **Feature-flagged home-manager** — composable profiles (`cliBase`,
  `desktopBase`, `adamrHome`, ...) shared across hosts via `self.homeModules.*`
- 💾 **Opt-in persistence** through impermanence + ephemeral btrfs snapshotting
- 🔒 **Encrypted, single-partition BTRFS** with LUKS + fido2/TPM unlock
- 📀 **Declarative disk partitioning** with [disko], including a cross-arch
  aarch64 image build for the cloud host
- 🔑 **Encrypted secrets** per-host via [sops-nix][sops] (age + PGP yubikeys)
- 🕸️ **Mesh-networked** hosts with tailscale (+ a direct WireGuard tunnel)
- 🚀 **Remote deploys** to the cloud VM via [deploy-rs]
- 🎮 A fully declarative Minecraft server, because why not

## Hosts

| Host | Purpose | Notes |
|---|---|---|
| `pc` | AMD desktop workstation | Hyprland (uwsm) + Cinnamon fallback, LUKS + fido2/TPM, secure boot, ephemeral btrfs |
| `msi-nixos` | MSI GS65 Stealth 8SF laptop | Intel + Nvidia PRIME (sync/offload), GRUB cryptodisk, TLP |
| `msi-server` | repurposed MSI Nightblade MI2 | headless, full self-hosted service stack, servers VLAN bridge |
| `oci` | Oracle Cloud free-tier VM | aarch64, disko cross-arch image build, serial console, Minecraft server |
| `vm` | throwaway test VM | minimal, for fast `nix eval` / sanity checks |
| `wsl` | NixOS on WSL2 | no disk/persistence concerns, work identity |

## Structure

```text
flake.nix              a single mkFlake { } call over inputs + import-tree ./modules
modules/
  flake/                flake-parts plumbing: systems list, the homeModules
                         option, overlays output, packages output
  nixos/                small reusable NixOS option modules
  home/
    options/             bare option declarations shared across profiles
                         (colors, fonts, monitors, wallpaper, ...)
    features/            composable HM profiles, one concern each
                         (ssh, gpg, gh, pass, productivity, games, helix,
                         impermanence, desktop/*)
    cli-base.nix          -> cliBase: shell + tools + git, safe for any user
    cli-workstation.nix   -> cliWorkstation: extra CLI for GUI hosts
    adamr/                adamr's identity + per-host home profiles
  hosts/
    default.nix           the ONLY place nixosSystem is called, once per host
    install-iso.nix       bootable install-media ISO package (`.#install-iso`)
    common/
      global/              globalDefaults aggregate: nix, ssh, fish, sops,
                           persistence, tailscale, ...
      users/               userAdamr account module + shared secrets
    features/
      desktop/             desktopBase aggregate: sddm, hyprland, cinnamon,
                           networking, yubikey, tpm, ...
      optional/            opt-in host features: docker, libvirtd, nginx,
                           disko-btrfs, steam, snapshots, ...
    pc/, msi-nixos/, msi-server/, oci/, vm/, wsl/
                           one directory per host
overlays/                nixpkgs overlays (flake-inputs alias, stable
                         channel, custom package patches)
pkgs/                    custom package derivations
docs/                    dendritic-overview.md, pc-migration.md, disk-resize.md
```

Composition is always via `self.nixosModules.<name>` / `self.homeModules.<name>`
in an `imports = [...]` list — never relative file imports between profiles.
Full details, including the two wiring quirks around `self`/`inputs`
availability in inner modules, are in [`docs/dendritic-overview.md`](docs/dendritic-overview.md).

## About the installation

Most hosts use a single btrfs partition (encrypted on everything except the
headless server) with subvolumes for `/nix`, an opt-in `/persist` directory
(via [impermanence]), a swap file, and a root subvolume that's wiped on every
boot when ephemeral rollback is enabled. Disk layout itself is declared with
[disko].

## How to bootstrap

All you need is Nix (any version). Run:

```sh
nix-shell
```

Or, if you already have Nix 2.4+, git, and `flakes` + `nix-command` enabled:

```sh
nix develop
```

Then:

```sh
nixos-rebuild --flake .#<host>            # build/switch a system configuration
nix build .#<package>                     # build/shell/run a package from pkgs/
nix build .#install-iso                   # build a bootable install-media ISO
deploy --hostname <ip> .#<host>    # ship the host with deploy-rs
```

home-manager isn't standalone here — every profile is wired as a NixOS module
(`home-manager.users.<user> = self.homeModules."<profile>"`), so it activates
automatically as part of `nixos-rebuild --flake`.

[`sops`][sops] manages secrets, [`disko`][disko] manages disk formatting and
partitioning, and [`nixos-anywhere`][nixos-anywhere] can install NixOS on any
remote system from scratch.

### Validating without hardware

Can't build the aarch64 `oci` host locally, and building the desktop hosts
fully is slow. For a quick correctness check, evaluate the toplevel
derivation path for any host — this catches option-type errors, missing
`self.nixosModules.*` references, and infinite recursion without building
anything:

```sh
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

Untracked new files are invisible to the flake until `git add`ed. Format with
`nix run nixpkgs#alejandra -- <files>` (2-space indent) before committing.

## Secrets

Deployment secrets (user passwords, service credentials, WireGuard keys, ...)
are managed with the excellent [`sops-nix`][sops]. Everything is encrypted
with my personal PGP key plus the relevant hosts' SSH host keys.
`.sops.yaml` at the repo root keys `creation_rules` by path regex — one rule
per host's `secrets.json`, plus a shared rule for the common user secrets.

## Tooling and applications I use

Daily drivers:

- hyprland (uwsm) + waybar + wofi, cinnamon as a fallback session
- alacritty / ghostty
- helix
- fish + atuin + zoxide + direnv + eza/bat/fd/rg
- gpg + pass
- tailscale
- podman / docker
- kdeconnect
- jujutsu (on top of git, for signed commits)

Some of the things I self-host:

- Minecraft (a modded Forge server on the `oci` host)
- a nix binary cache

Nixy stuff:

- flake-parts + import-tree (the dendritic pattern itself)
- home-manager
- sops-nix
- impermanence
- disko
- deploy-rs
- nix-minecraft
- ...and NixOS and Nix itself, of course :)

Let me know if you have any questions about any of it :)

[sops]: https://github.com/Mic92/sops-nix
[disko]: https://github.com/nix-community/disko
[deploy-rs]: https://github.com/serokell/deploy-rs
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
[impermanence]: https://github.com/nix-community/impermanence
[flake-parts]: https://flake.parts
[import-tree]: https://github.com/vic/import-tree
[nix-starter-config]: https://github.com/Misterio77/nix-starter-config

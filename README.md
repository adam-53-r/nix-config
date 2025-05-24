[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

# My NixOS configurations

Here's my NixOS/home-manager config files. Requires [Nix flakes](https://nixos.wiki/wiki/Flakes).

> [!IMPORTANT]  
> This config was originally forked from [Misterio77's config](https://github.com/Misterio77/nix-config) which I strongly recommend checking out as well as all his other amazing work.
> If you're looking for something simpler to start out with flakes try [Misterio77's starter config repo](https://github.com/Misterio77/nix-starter-config).

**Highlights**:

- Multiple **NixOS configurations**, including **laptop**, **server**
- **Opt-in persistence** through impermanence + blank snapshotting
- **Encrypted** single **BTRFS** partition
- **Declarative** disk partitioning and formatting with [disko]
- Fully **declarative self-hosted** apps like [Nextcloud](https://nextcloud.com)
- Deployment **secrets** using [**sops-nix**][sops]
- **Mesh networked** hosts with **tailscale**
- Flexible **Home Manager** Configs through **feature flags**

## Structure

- `flake.nix`: Entrypoint for hosts and home configurations. Also exposes a
  devshell for boostrapping (`nix develop` or `nix-shell`) and other config for tools like [deploy-rs].
<!-- - `lib`: A few lib functions for making my flake cleaner -->
- `hosts`: NixOS Configurations, accessible via `nixos-rebuild --flake`.
  - `common`: Shared configurations consumed by the machine-specific ones.
    - `global`: Configurations that are globally applied to all my machines.
    - `optional`: Opt-in configurations my machines can use.
  - `msi-nixos`: Msi Laptop GS65 Stealth 8SF - 32GB RAM, i7-8750H, RTX 2070 Mobile | Hyprland
  - `danix`: Legion ... - 32GB RAM, i7-8750H, RTX 3070 Mobile | Hyprland
  - `msi-server`: Repurposed MSI Nightblade MI2 Server - 16GB RAM, i5-6400 | GTX 960 | Server
  - `nixos-htb`: Qemu VM for [HTB](https://www.hackthebox.com/) | VM
  - `vm-tests`: Qemu VM for testing | VM
- `home`: My Home-manager configuration, acessible via `home-manager --flake`
    - Each directory here is a "feature" each hm configuration can toggle, thus
      customizing my setup for each machine (be it a server, desktop, laptop,
      anything really).
- `modules`: A few actual modules (with options) I haven't upstreamed yet.
- `overlay`: Patches and version overrides for some packages. Accessible via
  `nix build`.
- `pkgs`: My custom packages. Also accessible via `nix build`. You can compose
  these into your own configuration by using my flake's overlay, or consume them through NUR.

## About the installation

Most installs use a single btrfs (encrypted on all except headless systems)
partition, with subvolumes for `/nix`, a `/persist` directory (which I opt in
using `impermanence`), swap file, and a root subvolume (cleared on every boot if ephemeral is enabled).

<!-- Home-manager is used in a standalone way, and because of opt-in persistence is
activated on every boot with `loginShellInit`. -->

## How to bootstrap

All you need is nix (any version). Run:
```
nix-shell
```

If you already have nix 2.4+, git, and have already enabled `flakes` and
`nix-command`, you can also use the non-legacy command:
```
nix develop
```

`nixos-rebuild --flake .` To build system configurations.

`home-manager --flake .` To build user configurations.

`nix build` (or shell or run) To build and use packages.

[`sops`][sops] To manage secrets.

[`disko`][disko] To manage disk formatting and partitioning.

[`deploy`][deploy-rs] To deploy configurations on remote systems.

[`nixos-anywhere`][nixos-anywhere] To install NixOS on any remote system.


## Secrets

For deployment secrets (such as user passwords and server service secrets), I'm
using the awesome [`sops-nix`][sops]. All secrets
are encrypted with my personal PGP key, as well as the
relevant systems's SSH host keys.

<!-- On my desktop and laptop, I use `pass` for managing passwords, which are
encrypted using (you bet) my PGP key. This same key is also used for mail
signing, as well as for SSH'ing around. -->

## Tooling and applications I use

Most relevant user apps daily drivers:

- hyprland + swayidle + swaylock
- waybar
- helix
- fish
- alacritty
- gpg + pass
- tailscale
- podman
- zathura
- wofi
- bat + fd + rg
- kdeconnect
- sublime-music

Some of the services I host:

- nextcloud
- plex server
- nix binary cache
<!-- - hydra -->
<!-- - navidrome -->
<!-- - deluge -->
<!-- - prometheus -->
<!-- - websites (such as https://m7.rs) -->
<!-- - minecraft -->
<!-- - headscale -->

Nixy stuff:

- nix-colors
- sops-nix
- impermanence
- home-manager
- deploy-rs
- and NixOS and nix itself, of course :)

Let me know if you have any questions about them :)

[sops]: https://github.com/Mic92/sops-nix
[disko]: https://github.com/nix-community/disko
[deploy-rs]: https://github.com/serokell/deploy-rs
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere

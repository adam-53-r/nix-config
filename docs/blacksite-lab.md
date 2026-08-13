# blacksite: the cybersecurity practice lab

A disposable NixOS guest, meant to run on `pc`, carrying a Kali-style
offensive-security toolbox plus a few deliberately-vulnerable targets to point
it at. Ephemeral btrfs root (wiped every boot), XFCE on X11, unencrypted on
purpose.

There is one `nixosConfigurations.blacksite`, and two ways to run it.

## 1. Throwaway QEMU VM (fastest loop)

Nothing to install, nothing to clean up. The `virtualisation.vmVariant` block in
`modules/hosts/blacksite/_vm-variant.nix` sizes it (8G RAM, 4 cores, 40G sparse
scratch disk) and turns off the ephemeral rollback and the impermanence bind
mounts, since neither has a partition to work with here.

```sh
nixos-rebuild build-vm --flake .#blacksite
./result/bin/run-blacksite-vm
```

- **Autologin** straight to XFCE; the greeter is skipped.
- **SSH from the host:** port 2222 is forwarded to the guest's 22.
  `ssh -X -p 2222 adamr@localhost` — key auth only (`PasswordAuthentication` is
  off globally), against the public keys `userAdamr` installs.
- **Moving files in/out:** the guest's `/tmp/shared` is the host directory named
  by `$SHARED_DIR`:
  ```sh
  mkdir -p ~/blacksite-share
  SHARED_DIR=~/blacksite-share ./result/bin/run-blacksite-vm
  ```
- **State does not survive**, including the scratch disk image
  (`blacksite.qcow2` in the invocation directory — delete it to reset).

## 2. Persistent guest under libvirt

`pc` already runs libvirtd + virt-manager (`optionalLibvirtd`). Build a disk
image and import it:

```sh
nix build .#nixosConfigurations.blacksite.config.system.build.diskoImages
# -> result/main.qcow2  (sparse, 80G ceiling)

install -m 600 result/main.qcow2 /var/lib/libvirt/images/blacksite.qcow2
virt-install \
  --name blacksite --memory 8192 --vcpus 4 \
  --disk /var/lib/libvirt/images/blacksite.qcow2,bus=virtio \
  --import --os-variant nixos-unstable \
  --video virtio --channel spicevmc --graphics spice
```

Here the ephemeral root *is* live: `/` is rolled back from a blank btrfs
subvolume on every boot, and only `/persist` survives (plus a few pre-wipe
snapshots under `/snapshots/pre-wipe`, per `diskoBtrfs`). What's persisted:

| Path | Why |
|---|---|
| `~/engagements` | lab work itself — one dir per box/challenge |
| `~/.msf4`, `/var/lib/postgresql` | metasploit history + its database |
| `~/.BurpSuite`, `~/.ZAP` | saved project/session state |
| `~/.john`, `~/.local/share/hashcat` | pot files (cracked hashes) |
| `~/.ghidra`, `~/.config/ghidra` | ghidra projects and layout |
| `~/.config/xfce4` | panel/appearance tweaks |
| `/etc/NetworkManager/system-connections` | saved connections, VPN imports |
| `/var/lib/containers` | pulled target images (from `globalPodman`) |

Rebuilding it afterwards is a normal `nixos-rebuild --flake .#blacksite switch`
from inside the guest (this flake checkout is not persisted there — clone it, or
drive the rebuild over ssh from the host).

## Credentials

The account is `adamr`, and **no password is set for it in this repo** — this
tree is public, and a committed hash is a credential in git forever even when
the cleartext is disposable. The host also isn't enrolled in `.sops.yaml` (it
has no host key to encrypt to until it's installed), so the shared
`adamr-password` secret can't be decrypted here either.

Nothing about that blocks normal use:

- **lightdm autologins** straight into XFCE, so booting the VM needs no
  credential at all.
- **sshd** takes the public keys `userAdamr` installs (password auth is off
  globally anyway).
- **`sudo` needs no password** on this host — half the toolbox is useless
  unprivileged.

What it does cost is the greeter after an explicit logout, and console login.
To get those, generate a hash on the box and keep it out of the tree:

```sh
sudo mkdir -p /persist/secrets
mkpasswd -m yescrypt | sudo tee /persist/secrets/adamr-password
```

then set `users.users.adamr.hashedPasswordFile` to that path — `/persist`
survives the boot wipe, and nothing lands in git. For a box that stops being
disposable, the better answer is enrolling it in `.sops.yaml` and dropping
`disable-user-sops`.

## What's installed

`optionalSecurityTools` (`modules/hosts/features/optional/security-tools.nix`)
is a reusable module with one opt-out flag per category — every category is on
here. Trim from the host with e.g. `security-tools.wireless = false;`.

| Category | Roughly |
|---|---|
| `recon` | nmap, masscan, rustscan, naabu, tcpdump, termshark, dns\*/subfinder/amass, smbmap, enum4linux-ng, bettercap, ettercap, responder |
| `web` | burpsuite, zap, mitmproxy, sqlmap, nuclei, nikto, ffuf/feroxbuster/gobuster, wpscan, dalfox, testssl |
| `exploitation` | metasploit, searchsploit, netexec, evil-winrm, pwncat, bloodhound, certipy, kerbrute, chisel, ligolo-ng |
| `credentials` | hashcat, john, hydra, medusa, ncrack, hashid, crunch, cewl |
| `reversing` | ghidra, radare2/rizin/cutter, gdb + gef, ropgadget, checksec, imhex, jadx/apktool, frida, aflplusplus |
| `forensics` | binwalk, foremost, sleuthkit, autopsy, volatility3, exiftool, steghide/stegseek/zsteg, yara, zeek, chainsaw |
| `wireless` | aircrack-ng, wifite2, kismet, mdk4, bully, pixiewps, hcxtools (needs a passed-through adapter) |
| `workflow` | openvpn, freerdp, remmina, tigervnc, wordlists, firefox, chromium, keepassxc, cherrytree |
| `python` | one `python3` with pwntools, impacket, scapy, pycryptodome, sympy, pypykatz importable |

Two conveniences worth knowing:

- **Wordlists live at Kali's paths.** `/usr/share/wordlists` and
  `/usr/share/seclists` are symlinks into the system profile, so
  `-w /usr/share/wordlists/rockyou.txt` works as written in any walkthrough.
  `lab wordlists` prints the real directory.
- **Wireshark** captures without root via the setcap `dumpcap` wrapper
  (`optionalWireshark`); `adamr` is in the `wireshark` group through
  `userAdamr`.

Deliberately absent: `mitm6` (still needs `future`, which doesn't support
python3.13, so it won't evaluate on this nixpkgs), `angr` (commented out of the
python env — large, slow-building, and only occasionally needed; `nix shell` it
when a challenge calls for it) and `pwndbg` (not packaged — `gef` is here
instead).

## Practice targets

Three vulnerable-by-design web apps run as podman units, **bound to loopback
only**. They're started on demand, so no boot depends on a registry pull:

```sh
lab list            # what exists, where, and whether it's running
lab up juice-shop   # pulls on first run
lab down all
```

| Target | URL | |
|---|---|---|
| `juice-shop` | http://127.0.0.1:3000 | OWASP Juice Shop — modern JS, ~100 challenges |
| `dvwa` | http://127.0.0.1:8080 | Damn Vulnerable Web App — classic PHP, difficulty dial |
| `webgoat` | http://127.0.0.1:8081 | OWASP WebGoat — guided lessons |

DVWA's login is `admin` / `password`, and it needs "Create / Reset Database"
clicked once on first visit.

## Keeping the lab pointed inward

The uncomfortable failure mode for a box like this isn't the VM breaking, it's a
stray scan against a production subnet, or a target container getting popped and
reaching something it shouldn't. Two things the config handles, and one it
can't:

- **Nothing listens off-box.** The targets bind to `127.0.0.1`, and the firewall
  stays on with only sshd exposed.
- **Not on the tailnet.** `tailscaled` runs but is never authenticated (no
  authKeyFile anywhere in this config), so blacksite can't see the other hosts
  until someone runs `tailscale up`. Routing features are off too. Worth leaving
  that way — a box full of scanners one hop from the rest of the tailnet is not
  a good trade.
- **Its default network isn't isolated.** Under libvirt the guest lands on
  `virbr0` (NAT), which can reach whatever the host can; under `build-vm` it's
  QEMU user-mode NAT, same story. For noisy scans, or a vulnerable target that
  isn't fully trusted, define an *isolated* libvirt network (virt-manager →
  Edit → Connection Details → Virtual Networks → add one with no forwarding)
  and attach blacksite plus its victim VMs to that. Isolated networks have no
  route off the host at all — which also means no internet, so pull images and
  update first.

Public practice ranges generally hand out an `.ovpn` profile; `openvpn` is
installed for that (`sudo openvpn --config <profile>.ovpn`), and
NetworkManager's applet can import the same file if a tray toggle is preferable.

## Notes

- `nix eval .#nixosConfigurations.blacksite.config.system.build.toplevel.drvPath`
  is the quick correctness check, as with every host here.
- The first build is large: ghidra, burpsuite, the JVM targets, seclists and the
  python env dominate the closure.
- The image build needs the same vmTools workaround as the `oci` host (disko
  hands vmTools a module-tree symlink merge with no `.target` attribute); see the
  comment in `modules/hosts/blacksite/_hardware.nix`.

# Remote power-on + unlock for pc

Two pieces, wired up in `modules/hosts/pc/_hardware.nix`:

1. **Wake-on-LAN** on `enp16s0` (RTL8126, MAC `34:5a:60:c8:ef:1f`) - lets you
   power the box on remotely.
2. **Initrd SSH** (`boot.initrd.network.ssh`) - lets you type the LUKS
   passphrase remotely when the TPM2 token refuses to unlock. LAN-only for
   now - not reachable from outside the home network without a router
   port-forward or WireGuard-in-initrd (not set up yet).
3. **TPM2 auto-unlock** (crypttab `tpm2-device=auto`) - the disk normally
   unlocks itself, so a WoL power-on boots to the login screen. If the TPM2
   token refuses, the boot falls back to the FIDO2 key, then the passphrase
   (console or initrd SSH). See "TPM2 enrollment" at the bottom.

## One-time setup (run these yourself - all need root/BIOS access this
session can't provide non-interactively)

### 1. BIOS

Reboot into BIOS setup and enable:
- **Settings -> Advanced -> Wake Up Event Setup -> Resume By PCI-E Device**
  (or similarly named "PCI Power Up" / "PME Event Wake Up")
- Disable **ErP** / **EuP Ready** (this cuts standby power to the NIC otherwise)
- Disable **Deep Sx** if present (keeps the NIC powered in S5/off state)

### 2. Generate the initrd SSH host key

Runs as your normal user, no root needed for generation - only for
installing it:

```fish
ssh-keygen -t ed25519 -N "" -C "pc-initrd" -f /tmp/ssh_host_ed25519_key
sudo install -d -m 0700 /etc/secrets/initrd
sudo install -m 0600 /tmp/ssh_host_ed25519_key /etc/secrets/initrd/ssh_host_ed25519_key
sudo install -m 0644 /tmp/ssh_host_ed25519_key.pub /etc/secrets/initrd/ssh_host_ed25519_key.pub
shred -u /tmp/ssh_host_ed25519_key /tmp/ssh_host_ed25519_key.pub
```

This path (`/etc/secrets/initrd/ssh_host_ed25519_key`) matches what's
referenced in `_hardware.nix`'s `boot.initrd.network.ssh.hostKeys`, and
`/etc/secrets/initrd` is now in `environment.persistence."/persist".directories`
in that same file - pc's root is ephemeral (wiped every reboot), so without
that line this key would disappear on the next reboot and rebuilds would
silently stop embedding a host key. It's **never committed to git** - it's a
real secret that only lives in `/persist` on this machine.

### 3. Rebuild and test *with physical access*

```fish
sudo nixos-rebuild boot --flake ~/mynix#pc
```

Use `boot`, not `switch`, for the first test - this only makes the new
generation the *next* boot default without touching the currently running
system, so if something's wrong with the new initrd (NIC driver, DHCP, sshd)
you're not mid-air. Reboot, and watch the console: it should still show the
normal FIDO2/passphrase prompt as before (initrd SSH is additive). Confirm
the network came up in initrd (DHCP lease on enp16s0) before trusting it
remotely.

If the new generation fails to boot cleanly for any reason: reboot again and
pick the previous generation from the Limine boot menu - NixOS keeps prior
generations automatically, this is the actual safety net for this change,
not a manual backup.

### 4. Verify Wake-on-LAN actually stuck

```fish
ethtool enp16s0 | grep Wake-on
```

Should show `Wake-on: g`. If it shows `d` (disabled) - `enp16s0`'s connection
is an **imperative NetworkManager profile** ("Wired connection", not
declared in nix), so NixOS's declarative `networking.interfaces.enp16s0.wakeOnLan`
can get overridden when NM activates the connection. Fix directly through NM
instead:

```fish
nmcli connection modify "Wired connection" 802-3-ethernet.wake-on-lan magic
nmcli connection down "Wired connection"; and nmcli connection up "Wired connection"
ethtool enp16s0 | grep Wake-on   # recheck
```

### 5. Test the full flow from another machine on the LAN

```fish
# power off pc first, then from another box on the same LAN:
wakeonlan 34:5a:60:c8:ef:1f
# wait a few seconds for POST + initrd, then find its DHCP lease (check your
# router, or arp -a) and:
ssh root@<pc-dhcp-ip>
# connecting runs `systemctl default`, which should prompt for the LUKS passphrase
```

Consider a DHCP reservation for `enp16s0`'s MAC on your router so the initrd
IP is predictable instead of hunting for a new lease every time.

## LUKS header backup (do before enrolling TPM2)

Do this before any keyslot operation:

```fish
sudo cryptsetup status pc   # underlying device - nvme0n1p4 as of 2026-10
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p4 --header-backup-file ~/pc-luks-header-(date +%F).img
chmod 600 ~/pc-luks-header-*.img
```

Store that file somewhere off this disk (it's small, a few MB) - it's the
thing that lets you recover if a keyslot operation ever corrupts the header.

## TPM2 enrollment

The token is bound to:

- PCR 0: firmware code
- PCR 1: firmware settings, SMBIOS, EFI boot entries and BootOrder
- PCR 2/3: option ROMs (GPU VBIOS) and their config
- PCR 5: GPT of the boot disk
- PCR 7: Secure Boot state and keys
- PCR 15 = 0: `tpm2-measure-pcr=yes` extends it on unlock, so the key can't
  be unsealed a second time in the same boot. Without a UKI this needs the
  `systemd.tpm2_measured_os=yes` kernel param.

PCR 4 is not bound because limine rewrites `BOOTX64.EFI` (config hash
enrollment) on every rebuild. That leaves BIOS "Image Execution Policy =
Deny Execute" as the guard against unsigned EFI binaries; sbctl flags this
board as allowing them by default (FQ0001).

Re-enroll after a BIOS update, BIOS setting change, boot entry change or
GPT change, once the boot has fallen back to FIDO2:

```fish
sudo systemd-cryptenroll /dev/nvme0n1p4 --wipe-slot=tpm2 --tpm2-device=auto \
  --unlock-fido2-device=auto \
  --tpm2-pcrs=0+1+2+3+5+7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
```

PCR 15 is passed as zero because the running system has already extended it.

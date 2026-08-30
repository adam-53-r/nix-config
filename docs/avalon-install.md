# Installing avalon (MSI GS65 Stealth 8SF)

`avalon` is a from-scratch install onto the whole internal NVMe — it replaces
the old `msi-nixos` config, and the rename is not survivable in place: the
btrfs partition is labelled `disk-main-<hostname>` and the LUKS mapper is named
after the host, so an existing `msi-nixos` disk would not be found.

The host is deliberately checked in with two **bootstrap-only** settings
(`disable-user-sops` and a `users.mutableUsers` override) because a fresh
install cannot yet decrypt the shared user secrets. Steps 5–6 remove them.

## 1. Boot the installer

Build the repo's own ISO on `pc` and write it to a USB stick:

```console
$ nix build .#install-iso
$ sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

In the GS65 firmware (Del at boot): disable Secure Boot **for now** (it gets
enrolled in step 7), and confirm the NVMe is in AHCI/NVMe mode rather than RST.

## 2. Partition and format

`disko` owns the whole layout — the ESP, the LUKS container, every btrfs
subvolume, and the 36G swapfile that hibernation writes into.

```console
$ sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko --flake github:adam-53-r/nix-config#avalon
```

Confirm with `lsblk` that `/dev/nvme0n1` is really the internal disk first; it
is hard-coded in `modules/hosts/avalon/_hardware.nix` and **this command erases
it**. The command prompts for the LUKS passphrase. That passphrase remains the
fallback once the YubiKey is enrolled in step 8, so it should be a strong one.

## 3. Install

```console
$ sudo nixos-install --flake github:adam-53-r/nix-config#avalon --no-root-password
$ sudo passwd -R /mnt adamr   # bootstrap password, replaced in step 6
$ sudo reboot
```

## 4. Get onto the network

There is no ethernet port on this chassis, so do this from the console before
anything else:

```console
$ nmtui
```

## 5. Rotate the sops host key

The install generated a brand-new ssh host key, so the `avalon` age identity in
`.sops.yaml` is stale. From `pc` (or on the laptop itself, against a clone):

```console
$ ssh-keyscan avalon | nix run nixpkgs#ssh-to-age
```

Paste the resulting `age1…` over the `&avalon` anchor in `.sops.yaml`, then
re-encrypt the shared secrets to it:

```console
$ nix run nixpkgs#sops -- updatekeys modules/hosts/common/users/secrets.json
```

## 6. Hand the password back to sops

In `modules/hosts/avalon/default.nix`, delete both bootstrap lines:

```nix
disable-user-sops = true;
users.mutableUsers = lib.mkForce true;
```

Commit, then rebuild. adamr's password now comes from sops like every other
host, and the account is immutable again:

```console
$ sudo nixos-rebuild switch --flake .#avalon
```

## 7. Secure boot

Same procedure as `pc` (`modules/hosts/features/optional/secure-boot.nix`), in
this order:

```console
$ sudo sbctl create-keys
# put the firmware into Secure Boot "setup mode", then:
$ sudo sbctl enroll-keys --microsoft
$ sudo nixos-rebuild switch --flake .#avalon
$ sudo sbctl verify        # every limine/kernel image should report signed
```

Re-enable Secure Boot in the firmware and reboot. `bootctl status` should now
report Secure Boot as enabled.

## 8. Enrol the YubiKey for LUKS

The host already passes `fido2-device=auto`; the token still has to be added to
the LUKS header:

```console
$ sudo systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
```

Verify by rebooting — it should ask for a touch, and fall through to the
passphrase if no key is present.

## 9. Verify the laptop-specific bits

```console
# msi-ec bound to the EC, and the charge limit applied
$ dmesg | grep -i msi-ec
$ cat /sys/class/power_supply/BAT*/charge_control_end_threshold   # expect 80
$ systemctl status msi-ec-charge-limit

# dGPU state. Note that RTD3 does not work on this chassis, for firmware
# reasons: the GS65's DSDT defines no _PR3 (D3cold power resources) on
# \_SB.PCI0.PEG0, the root port above the GPU, which is what NVIDIA requires.
# Expect "Runtime D3 status: Not supported" with Video Memory Active on either
# module flavor, meaning the card draws power whenever the nvidia module is
# loaded. The `battery-saver` generation is the way to turn it off.
# To re-check the firmware side:
#   nix shell nixpkgs#acpica-tools -c sh -c 'acpidump -b && iasl -d dsdt.dat'
#   grep -n "_PR3" dsdt.dsl        # only XDCI and the Thunderbolt VOLn devices
$ cat /proc/driver/nvidia/gpus/0000:01:00.0/power
$ cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
$ nvidia-offload glxinfo | grep "OpenGL renderer"                 # expect the RTX

# power policy
$ sudo tlp-stat -s -p
$ systemctl status thermald

# hibernation: zram takes the paging load, the swapfile is the image target
$ swapon --show     # zram at priority 5, /swap/swapfile below it
$ cat /sys/power/state    # must list "disk"; see the note below if it does not
$ sudo systemctl hibernate
```

After it comes back, the check that distinguishes a resume from a cold boot is
the boot ID, which a resume does not change:

```console
$ journalctl --list-boots | tail -2   # a new entry means it did not resume
$ journalctl -b 0 | grep -iE 'hibernation (entry|exit)|Waking up from'
```

Two things in that log look wrong and are not. There are no `Image saving` or
`Image loading` lines, and the log jumps from allocating the snapshot straight
to `Waking up from system sleep state S4` — everything the kernel wrote after
`swsusp_save()` took the snapshot lived only in the ring buffer that gets
discarded on restore. For the same reason journald stamps the pre-snapshot
lines with the resume time. `PM: Image not found (code -16)` is the resume
check that runs *before* hibernating, not a failure.

This unit's EC reports `16Q4EMS1.109`, which upstream does not list, so msi-ec
refuses to bind on its own. `_power.nix` already forces the adjacent profile
for the same board (`options msi_ec firmware=16Q4EMS1.110`); without that
override there is no charge limit at all.

## Notes

- The `battery-saver` boot entry (nixos-hardware) removes the dGPU from the PCI
  bus entirely. External displays do **not** work in it — HDMI and mini-DP are
  wired to the nvidia card on this chassis — so it is for unplugged sessions.
- Hibernation and the ephemeral root interact: `diskoBtrfs`'s initrd rollback
  is explicitly ordered *after* `systemd-hibernate-resume.service`, so a
  successful resume never reaches the wipe. Do not reorder that.
- If `/sys/power/state` stops listing `disk` (`/sys/power/disk` reads
  `[disabled]`, and logind quietly downgrades `suspend-then-hibernate` to plain
  suspend), the config is not at fault. `hibernation_available()` is a runtime
  check, and with lockdown unbuilt, no `nohibernate` on the cmdline and no CXL
  present, the remaining gate is `secretmem_active()` — hibernation is refused
  for as long as any live process holds a `memfd_secret`. Find the holder with
  `sudo grep -l 'memfd:secret' /proc/[0-9]*/maps`.
- The hibernation splash (`optionalPlymouthHibernate`) has to switch VTs to get
  DRM master away from the compositor. To exercise that handoff on its own,
  without waiting on a hibernate cycle:

  ```console
  $ sudo chvt 8 && sudo plymouthd --mode=shutdown --attach-to-session \
      && sudo plymouth show-splash && sleep 5 && sudo plymouth quit; sudo chvt 1
  ```

  If the splash does not appear, the compositor kept the device; see the
  fallback noted in the module.
- No `resume_offset` is configured anywhere on purpose. systemd (≥ 255) records
  the hibernation location in the `HibernateLocation` EFI variable and computes
  the btrfs physical offset itself, so the classic `btrfs inspect-internal
  map-swapfile` dance is not needed.

# To-Do List
1. Automate qemu upgrades:
    Everytime qemu updates, its breaks the vms because their config isn't updated to point to the new qemu path.
    possible solution: `sd "/nix/store/.+?/" "$(nix eval --inputs-from self --raw nixpkgs#qemu)/" /var/lib/libvirt/qemu/NixOS-tests.xml`

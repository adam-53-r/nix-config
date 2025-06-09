{pkgs, ...}: {
  imports = [
    ./fish
    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./gh.nix
    ./git.nix
    ./gpg.nix
    ./jujutsu.nix
    ./lyrics.nix
    ./nushell.nix
    ./nix-index.nix
    ./pfetch.nix
    ./ssh.nix
    ./xpo.nix
    ./fzf.nix
    ./jira.nix
    ./wine.nix
    ./byobu.nix
    ./nb.nix
    ./aws.nix
  ];
  home.packages = with pkgs; [
    uutils-coreutils-noprefix
    iputils
    comma # Install and run programs by sticking a , before them
    distrobox # Nice escape hatch, integrates docker images with my environment

    bc # Calculator
    bottom # System viewer
    ncdu # TUI disk usage
    gdu # TUI disk usage
    eza # Better ls
    ripgrep # Better grep
    fd # Better find
    httpie # Better curl
    jq # JSON pretty printer and manipulator
    timer # To help with my ADHD paralysis
    tldr # Get command common usages

    nixd # Nix LSP
    alejandra # Nix formatter
    nixfmt-rfc-style
    nvd # Differ
    nix-diff # Differ, more detailed
    nix-output-monitor
    nh # Nice wrapper for NixOS and HM

    python3
    wget
    vim
    inetutils
    nix-tree
    keyutils
    efibootmgr
    
    zip
    xz
    unzip
    p7zip

    yq-go
    fzf

    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc

    file
    tree
    
    hugo
    glow

    btop
    iotop
    iftop

    ltrace
    lsof

    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    gptfdisk
    parted
    tparted

    hashid
    devenv
    esptool
    esphome
    platformio
    trash-cli
    apacheHttpd
    perf-tools
    flamegraph
    cargo-flamegraph

    sops
    ssh-to-age
    gnupg
    age
    deploy-rs
    nixos-anywhere
  ];
}

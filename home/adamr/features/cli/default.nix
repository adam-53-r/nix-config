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
    ./zoxide.nix
    ./yazi.nix
    ./zellij.nix
    ./lazygit.nix
    ./flatpak.nix
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
    lsd # Modern 'ls' replacement with colorful, tree-like output and git integration
    dust # Rust-based disk usage analyzer with live updates and sorting
    duf # Disk Usage Free - terminal-based disk usage analyzer with ncurses interface
    broot # Tree-like file explorer with git status integration and disk usage visualization
    choose # Modern replacement for cut command with improved syntax and functionality
    sd # Fast, modern sed replacement written in Rust for searching and replacing text
    cheat # Command-line cheat sheet viewer with examples and documentation
    glances # System monitoring tool providing comprehensive resource usage overview
    hyperfine # Modern benchmarking tool for shell commands with statistical analysis
    gping # Graphical ping utility with latency visualization
    procs # Modern ps replacement with improved terminal interface and filtering
    curlie # Modern curl wrapper with improved UX and JSON highlighting
    xh # HTTP client tool with improved syntax and colorized output
    doggo # DNS lookup tool with improved error handling and response formatting
    fx

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

    ansible
    yaml-language-server
    # ansible-language-server Unmaintained

    iperf3
    dnsutils
    ldns
    aria2
    socat
    nmap
    ipcalc
    tcpdump

    file
    tree

    hugo
    glow

    btop
    iotop
    iftop

    pkgs.stable.ltrace
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
    localstack
    dysk

    sops
    ssh-to-age
    gnupg
    age
    deploy-rs
    nixos-anywhere
  ];
}

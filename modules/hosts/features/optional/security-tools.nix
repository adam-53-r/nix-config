# Offensive-security / CTF toolbox, in the spirit of Kali's metapackages but
# grouped into opt-out categories so a host can take the whole kit (blacksite)
# or cherry-pick a slice of it.
#
# Deliberately packages ONLY: no services, no groups, no wordlist symlinks.
# Anything stateful (postgresql for msfdb, the wireshark dumpcap wrapper, the
# /usr/share/wordlists compatibility link) belongs to the importing host, so
# that adding this module to an existing machine can never change its runtime
# behaviour — it only grows $PATH.
#
# Every category defaults to ON: importing the module is the opt-in, and a host
# trims what it does not want (`security-tools.wireless.enable = false;`).
{
  flake.nixosModules.optionalSecurityTools = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.security-tools;

    mkCategory = description:
      lib.mkOption {
        type = lib.types.bool;
        default = true;
        inherit description;
      };

    # One interpreter carrying the libraries these workflows assume are
    # importable (`from pwn import *`, `from impacket... import`). Installing the
    # individual python3Packages.* into systemPackages would put their
    # entry-point scripts on $PATH but leave the modules unimportable, so the
    # env is the only correct shape here. Its bin/ still exports the scripts
    # (pwn, impacket's secretsdump.py, ROPgadget, ...).
    ctfPython = pkgs.python3.withPackages (ps:
      with ps; [
        # exploit dev
        pwntools
        ropgadget
        # angr is left out for now — it drags in a large, slow-building tree
        # for something only a minority of challenges need. capstone/unicorn
        # below cover the common cases; `nix shell nixpkgs#python3Packages.angr`
        # covers the rest without putting it in every rebuild.
        # angr
        capstone
        unicorn
        # network / protocol
        scapy
        impacket
        requests
        dnspython
        paramiko
        # crypto challenges
        pycryptodome
        sympy
        gmpy2
        # windows/AD credential material
        pypykatz
      ]);

    recon = with pkgs; [
      # port/host discovery
      nmap
      nmap-formatter
      masscan
      rustscan
      naabu
      arp-scan
      netdiscover
      hping
      # sockets & capture
      netcat-gnu
      socat
      tcpdump
      termshark
      tcpflow
      tcpreplay
      # dns / osint
      dnsutils
      whois
      traceroute
      dnsrecon
      dnsenum
      fierce
      dnsx
      subfinder
      amass
      asnmap
      shuffledns
      theharvester
      # service enumeration
      smbmap
      enum4linux
      enum4linux-ng
      samba # smbclient / rpcclient
      nfs-utils # showmount
      openldap # ldapsearch
      ldapvi
      net-snmp
      snmpcheck
      onesixtyone
      nbtscan
      sipvicious
      # on-path / lan attacks
      bettercap
      ettercap
      responder
      macchanger
      # NOTE: mitm6 (the usual IPv6-DNS-takeover partner to responder) is
      # omitted: it still depends on `future`, which does not support
      # python3.13, so it fails to evaluate on this nixpkgs. Reach for
      # `nix shell` against an older nixpkgs if a lesson needs it.
    ];

    web = with pkgs; [
      # intercepting proxies
      burpsuite
      zap
      mitmproxy
      # scanners
      nikto
      nuclei
      whatweb
      wpscan
      sqlmap
      commix
      dalfox
      # content discovery
      ffuf
      feroxbuster
      gobuster
      dirb
      wfuzz
      arjun
      katana
      hakrawler
      gau
      waybackurls
      # tls
      sslscan
      testssl
      # supporting cast
      interactsh # out-of-band interaction callbacks
      gowitness # bulk screenshots
      httpx
      cewl
      gitleaks
      trufflehog
    ];

    exploitation = with pkgs; [
      metasploit
      exploitdb # searchsploit
      netexec # the maintained crackmapexec successor
      evil-winrm
      pwncat
      # active directory
      kerbrute
      certipy
      bloodhound
      bloodhound-py
      # pivoting / tunnelling
      chisel
      ligolo-ng
    ];

    credentials = with pkgs; [
      hashcat
      hashcat-utils
      john
      thc-hydra
      medusa
      ncrack
      # hash triage
      hashid
      hash-identifier
      # candidate generation
      crunch
      rsmangler
      cewl
    ];

    reversing = with pkgs; [
      # disassemblers / decompilers
      ghidra
      radare2
      rizin
      cutter
      # debuggers
      gdb
      gef
      gdb-dashboard
      rr
      valgrind
      # binary triage
      checksec
      ropgadget
      one_gadget
      binutils
      patchelf
      upx
      lief
      capstone
      z3
      # hex editors
      imhex
      hexedit
      hexyl
      # tracing
      strace
      ltrace
      # android / jvm
      apktool
      jadx
      dex2jar
      procyon
      frida-tools
      # fuzzing
      aflplusplus
      honggfuzz
      radamsa
      # ctf convenience
      pwninit
    ];

    forensics = with pkgs; [
      # carving / filesystem
      binwalk
      foremost
      testdisk
      sleuthkit
      autopsy
      # memory
      volatility3
      # metadata / stego
      exiftool
      steghide
      stegseek
      zsteg
      outguess
      # detection content & log triage
      yara
      zeek
      chainsaw
      hayabusa
      sqlitebrowser
    ];

    wireless = with pkgs; [
      aircrack-ng
      airgeddon
      wifite2
      kismet
      mdk4
      bully
      pixiewps
      cowpatty
      hcxtools
      hcxdumptool
      horst
      iw
      wirelesstools
    ];

    # Getting to a target and keeping notes on it: VPN clients for the public
    # practice ranges (which typically hand out an .ovpn profile),
    # remote-desktop clients for whatever the target runs, and somewhere to
    # keep findings.
    workflow = with pkgs; [
      openvpn
      wireguard-tools
      freerdp
      remmina
      tigervnc
      sshpass
      # wordlists: this single package symlink-joins rockyou + seclists +
      # nmap's + wfuzz's lists under share/wordlists, and ships the
      # `wordlists` / `wordlists_path` helper commands.
      wordlists
      # browsers — a proxy-able one for Burp/ZAP, plus chromium for gowitness
      firefox
      chromium
      keepassxc
      cherrytree
      flameshot
      xclip
      wl-clipboard
    ];
  in {
    key = "mynix#nixosModules.optionalSecurityTools";

    options.security-tools = {
      recon = mkCategory "network discovery, enumeration and on-path tooling";
      web = mkCategory "web application proxies, scanners and content discovery";
      exploitation = mkCategory "exploitation frameworks, AD tooling and pivoting";
      credentials = mkCategory "password cracking and candidate generation";
      reversing = mkCategory "disassemblers, debuggers, fuzzers and CTF exploit-dev";
      forensics = mkCategory "carving, memory analysis, stego and log triage";
      wireless = mkCategory "802.11 auditing (needs a passed-through adapter to be useful)";
      workflow = mkCategory "VPN/RDP clients, wordlists, browsers and note-taking";
      python = mkCategory "a python3 env with pwntools/impacket/scapy importable";
    };

    config.environment.systemPackages =
      lib.optionals cfg.recon recon
      ++ lib.optionals cfg.web web
      ++ lib.optionals cfg.exploitation exploitation
      ++ lib.optionals cfg.credentials credentials
      ++ lib.optionals cfg.reversing reversing
      ++ lib.optionals cfg.forensics forensics
      ++ lib.optionals cfg.wireless wireless
      ++ lib.optionals cfg.workflow workflow
      ++ lib.optional cfg.python ctfPython;
  };
}

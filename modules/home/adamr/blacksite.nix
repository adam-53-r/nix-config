# Per-host home profile: adamr on the blacksite security lab.
#
# adamrHome (cliBase + gpg/ssh/gh + identity), plus persistence for the tool
# state that is genuinely annoying to lose on a box whose root is wiped every
# boot: an in-progress Burp project, msf history, cracked hashes.
# Deliberately NOT cliWorkstation — that layer is pc's dev tooling (wine,
# embedded toolchains, profilers) and has nothing to do with this box.
{self, ...}: {
  flake.homeModules."adamr@blacksite" = {...}: {
    imports = [self.homeModules.adamrHome];

    myPersistence.enable = true;

    home.persistence."/persist".directories = [
      # Where lab work goes: one directory per box or challenge.
      # Kept out of ~/Documents (which adamrHome already persists) so it is
      # obvious what belongs to the lab and can be wiped wholesale.
      "engagements"

      # Tool state worth surviving a reboot.
      ".msf4" # metasploit console history, loot, local db config
      ".BurpSuite" # license/config + saved project state
      ".ZAP" # zap session data and add-ons
      ".john" # john's pot file (cracked hashes)
      ".local/share/hashcat" # hashcat potfile + session restore points
      ".config/ghidra" # ghidra tool layout + key bindings
      ".ghidra" # ghidra project data
      ".config/xfce4" # panel/appearance tweaks (xfconf)
      ".cache/mozilla" # keeps firefox from re-warming on every boot
    ];
  };
}

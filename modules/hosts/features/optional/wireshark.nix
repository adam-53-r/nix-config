# Wireshark with the setcap dumpcap wrapper (wireshark group).
{
  flake.nixosModules.optionalWireshark = {pkgs, ...}: {
    key = "mynix#nixosModules.optionalWireshark";

    programs.wireshark.enable = true;

    environment.systemPackages = with pkgs; [wireshark tshark];
  };
}

# Printing via CUPS.
{
  flake.nixosModules.desktopPrinting = {
    key = "mynix#nixosModules.desktopPrinting";

    services.printing.enable = true;
  };
}

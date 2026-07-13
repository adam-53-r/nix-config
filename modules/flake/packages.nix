# Per-system outputs: custom packages and the formatter.
{
  perSystem = {pkgs, ...}: {
    packages = import ../../pkgs {inherit pkgs;};
    formatter = pkgs.alejandra;
  };
}

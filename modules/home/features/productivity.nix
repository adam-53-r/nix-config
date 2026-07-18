# Productivity tools. main also carried khal/khard/todoman/vdirsyncer/neomutt,
# all commented out as broken and still pointing at the upstream author's dav
# server — not ported (git history on main has them if ever wanted).
{
  flake.homeModules.homeProductivity = {pkgs, ...}: {
    services.syncthing.enable = true;
    home.persistence."/persist".directories = [".local/state/syncthing"];
  };
}

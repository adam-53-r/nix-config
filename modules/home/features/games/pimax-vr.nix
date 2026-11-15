# User side of the Pimax VR setup: the device configs the Monado driver reads,
# and xrizer so OpenVR (SteamVR) games run on Monado.
{
  flake.homeModules.homePimaxVr = {pkgs, ...}: let
    # Display and controller configs extracted from Pimax Play.
    pimax-configs = pkgs.fetchFromGitLab {
      owner = "notfranko";
      repo = "pimax-configs";
      rev = "0a0fdccc0cd69821dddf7d4a3e8fcc942e45328c";
      hash = "sha256-bUFGpl5VnZSrwuXwb6c/MzUcIv3htLq2sMmeK774e/4=";
    };
  in {
    # Linked one level down: the driver caches calibration next to these.
    xdg.configFile = {
      "monado/pimax_p3c/controllers".source = "${pimax-configs}/controllers";
      "monado/pimax_p3c/displays".source = "${pimax-configs}/displays";

      "openvr/openvrpaths.vrpath".text = builtins.toJSON {
        version = 1;
        runtime = ["${pkgs.xrizer}/lib/xrizer"];
      };
    };
  };
}

 {
  pkgs,
  ...
}: {
  imports = [
    ./global
    ./features/desktop/cinnamon
    ./features/games
    # ./features/desktop/wireless
    # ./features/rgb
    # ./features/productivity
    # ./features/pass
    # ./features/games/star-citizen.nix
    # ./features/games/shadps4.nix
  ];

  home.file = {
    ".config/cinnamon-monitors.xml" = {
      text = ''
        <monitors version="2">
          <configuration>
            <logicalmonitor>
              <x>1920</x>
              <y>0</y>
              <scale>1</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>DP-0</connector>
                  <vendor>NSL</vendor>
                  <product>ICARUS-F24</product>
                  <serial>0x00000001</serial>
                </monitorspec>
                <mode>
                  <width>1920</width>
                  <height>1080</height>
                  <rate>143.99276733398438</rate>
                </mode>
              </monitor>
            </logicalmonitor>
            <logicalmonitor>
              <x>0</x>
              <y>0</y>
              <scale>1</scale>
              <monitor>
                <monitorspec>
                  <connector>eDP-1-1</connector>
                  <vendor>AUO</vendor>
                  <product>0x80ed</product>
                  <serial>0x00000000</serial>
                </monitorspec>
                <mode>
                  <width>1920</width>
                  <height>1080</height>
                  <rate>144.02792358398438</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      '';
    };
  };

  # Red
  # wallpaper = pkgs.wallpapers.aenami-dawn;

  #  ------   -----   ------
  # | DP-3 | | DP-1| | DP-2 |
  #  ------   -----   ------
  # monitors = [
  #   {
  #     name = "DP-1";
  #     width = 2560;
  #     height = 1080;
  #     workspace = "1";
  #     primary = true;
  #   }
  #   {
  #     name = "DP-2";
  #     width = 1920;
  #     height = 1080;
  #     position = "auto-right";
  #     workspace = "2";
  #   }
  # ];
}
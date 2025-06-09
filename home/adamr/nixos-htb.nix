{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./global
    ./features/desktop/cinnamon
  ];

  home.persistence."/persist/${config.home.homeDirectory}".enable = lib.mkForce false;

  home.file = {
    ".config/cinnamon-monitors.xml" = {
      text = ''
        <monitors version="2">
          <configuration>
            <logicalmonitor>
              <x>0</x>
              <y>0</y>
              <scale>1</scale>
              <primary>yes</primary>
              <monitor>
                <monitorspec>
                  <connector>Virtual-1</connector>
                  <vendor>unknown</vendor>
                  <product>unknown</product>
                  <serial>unknown</serial>
                </monitorspec>
                <mode>
                  <width>1920</width>
                  <height>1080</height>
                  <rate>60</rate>
                </mode>
              </monitor>
            </logicalmonitor>
          </configuration>
        </monitors>
      '';
    };
  };
}

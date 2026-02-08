{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./global
    ./features/desktop/cinnamon
    ./features/desktop/hyprland
    ./features/desktop/wayvnc.nix
    ./features/games
    ./features/productivity
    ./features/pass
  ];

  # Red
  wallpaper = pkgs.inputs.themes.wallpapers.berserk-blood-moon;

  programs.ssh.includes = ["local.conf"];

  monitors = [
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      workspace = "1";
      position = "0x0";
      refreshRate = 120;
    }
    {
      name = "DP-3";
      width = 2560;
      height = 1440;
      workspace = "2";
      position = "auto-right";
      primary = true;
      refreshRate = 180;
    }
  ];

  home.persistence."/persist".directories = [
    ".config/Yubico"
    ".var"
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [
        "qemu:///system"
        "qemu+ssh://adamr@msi-server/system"
      ];
      uris = [
        "qemu:///system"
        "qemu+ssh://adamr@msi-server/system"
      ];
    };
  };

  # home.file = {
  #   ".config/cinnamon-monitors.xml" = {
  #     text = ''
  #       <monitors version="2">
  #         <configuration>
  #           <logicalmonitor>
  #             <x>1920</x>
  #             <y>0</y>
  #             <scale>1</scale>
  #             <primary>yes</primary>
  #             <monitor>
  #               <monitorspec>
  #                 <connector>DP-0</connector>
  #                 <vendor>NSL</vendor>
  #                 <product>ICARUS-F24</product>
  #                 <serial>0x00000001</serial>
  #               </monitorspec>
  #               <mode>
  #                 <width>1920</width>
  #                 <height>1080</height>
  #                 <rate>143.99276733398438</rate>
  #               </mode>
  #             </monitor>
  #           </logicalmonitor>
  #           <logicalmonitor>
  #             <x>0</x>
  #             <y>0</y>
  #             <scale>1</scale>
  #             <monitor>
  #               <monitorspec>
  #                 <connector>eDP-1-1</connector>
  #                 <vendor>AUO</vendor>
  #                 <product>0x80ed</product>
  #                 <serial>0x00000000</serial>
  #               </monitorspec>
  #               <mode>
  #                 <width>1920</width>
  #                 <height>1080</height>
  #                 <rate>144.02792358398438</rate>
  #               </mode>
  #             </monitor>
  #           </logicalmonitor>
  #         </configuration>
  #       </monitors>
  #     '';
  #   };
  # };
}

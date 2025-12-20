{
  description = "My NixOS Config";
  nixConfig = {
    extra-substituters = [
      "https://cache.arm53.xyz"
    ];
    extra-trusted-public-keys = [
      "cache.arm53.xyz:GEscuhzZqqKd7b3xFFk3AjKAJoYCGVcTimTYq56mcH8="
    ];
  };
  inputs = {
    # Nix ecosystem
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My own programs, packaged with nix
    themes = {
      url = "github:adam-53-r/themes";
      inputs.systems.follows = "systems";
    };
    nix-colors.url = "github:misterio77/nix-colors";

    # Third party programs, packaged with nix
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gl = {
      url = "github:nix-community/nixgl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
    systems.url = "github:nix-systems/default-linux";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hardware.url = "github:nixos/nixos-hardware";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    systems,
    nixos-generators,
    deploy-rs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});

    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs {inherit system;};
    # nixpkgs with deploy-rs overlay but force the nixpkgs package
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        # deploy-rs.overlay # or deploy-rs.overlays.default
        deploy-rs.overlays.default
        (self: super: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];
    };
  in {
    inherit lib;

    nixosModules = (import ./modules/nixos) // {
      wsl-base = import ./hosts/wsl;
    };
    homeManagerModules = (import ./modules/home-manager) // {
      wsl-base = import ./home/adamr/wsl.nix;
    };

    overlays = import ./overlays {inherit inputs outputs pkgs;};
    hydraJobs = import ./hydra.nix {inherit inputs outputs;};

    # Importing custom packages and nixos-generate configs
    packages =
      forEachSystem (pkgs: import ./pkgs {inherit pkgs;})
      // {
        x86_64-linux =
          (import ./pkgs {inherit pkgs;})
          // {
            install-iso = import ./install-iso.nix {inherit lib nixos-generators;};
          };
      };
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    nixosConfigurations = {
      #################
      # Adam Machines #
      #################
      # Main Laptop
      msi-nixos = lib.nixosSystem {
        modules = [
          ./hosts/msi-nixos
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      pc = lib.nixosSystem {
        modules = [
          ./hosts/pc
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # msi-server
      msi-server = lib.nixosSystem {
        modules = [
          ./hosts/msi-server
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # Windows WSL
      wsl = lib.nixosSystem {
        modules = [
          ./hosts/wsl
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # vm-tests
      vm-tests = lib.nixosSystem {
        modules = [
          ./hosts/vm-tests
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

      # # VM for HackTheBox
      # nixos-htb = lib.nixosSystem {
      #   modules = [
      #     ./hosts/nixos-htb
      #   ];
      #   specialArgs = {
      #     inherit inputs outputs;
      #   };
      # };

      # raspberrypi
      # raspberrypi = lib.nixosSystem {
      #   modules = [
      #     ./hosts/raspberrypi
      #   ];
      #   specialArgs = {
      #     inherit inputs outputs;
      #   };
      # };

      #################
      # Dani Machines #
      #################
      # Dani Laptop
      danix = lib.nixosSystem {
        modules = [
          ./hosts/danix
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };
    };

    homeConfigurations = {
      ##############
      # Adam users #
      ##############
      # Adam laptop
      "adamr@msi-nixos" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/msi-nixos.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam laptop
      "adamr@pc" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/pc.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam msi-server
      "adamr@msi-server" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/msi-server.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam msi-windows
      "adamr@wsl" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/wsl.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam work pc
      "adamr@work" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/work.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam vm-tests
      "adamr@vm-tests" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/vm-tests.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Adam nixos-htb
      # "adamr@nixos-htb" = lib.homeManagerConfiguration {
      #   modules = [
      #     ./home/adamr/nixos-htb.nix
      #     ./home/adamr/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.x86_64-linux;
      #   extraSpecialArgs = {
      #     inherit inputs outputs;
      #   };
      # };

      # Adam raspberrypi
      # "adamr@raspberrypi" = lib.homeManagerConfiguration {
      #   modules = [
      #     ./home/adamr/raspberrypi.nix
      #     ./home/adamr/nixpkgs.nix
      #   ];
      #   pkgs = pkgsFor.aarch64-linux;
      #   extraSpecialArgs = {
      #     inherit inputs outputs;
      #   };
      # };

      ##############
      # Dani users #
      ##############
      # Dani laptop
      "kali@kali" = lib.homeManagerConfiguration {
        modules = [
          ./home/dani/kali.nix
          ./home/dani/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };

      # Dani laptop
      "dani@danix" = lib.homeManagerConfiguration {
        modules = [
          ./home/dani/danix.nix
          ./home/dani/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
    };

    # Deploy-rs configs
    deploy = let
      activate-nixos = deployPkgs.deploy-rs.lib.activate.nixos;
      activate-hm = deployPkgs.deploy-rs.lib.activate.home-manager;
    in {
      sshOpts = ["-A"];
      nodes = {
        #################
        # Adam Machines #
        #################
        pc = {
          hostname = "pc";
          sshUser = "root";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.pc;
            };
          };
        };

        msi-nixos = {
          hostname = "msi-nixos";
          sshUser = "root";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.msi-nixos;
            };
          };
        };

        msi-server = {
          hostname = "msi-server";
          sshUser = "root";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.msi-server;
            };
          };
        };

        vm-tests = {
          hostname = "vm-tests";
          sshUser = "root";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.vm-tests;
            };
          };
        };

        nixos-htb = {
          hostname = "nixos-htb";
          sshUser = "root";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.nixos-htb;
            };
          };
        };

        # raspberrypi = {
        #   hostname = "raspberrypi";
        #   profiles = {
        #     system = {
        #       user = "root";
        #       path = activate-nixos self.nixosConfigurations.raspberrypi;
        #     };
        #   };
        # };

        #################
        # Dani Machines #
        #################
        kali = {
          hostname = "kali";
          profiles = {
            hm-kali = {
              user = "kali";
              path = activate-hm self.homeConfigurations."kali@kali";
            };
          };
        };

        danix = {
          hostname = "danix";
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.danix;
            };
          };
        };
      };
    };
  };
}

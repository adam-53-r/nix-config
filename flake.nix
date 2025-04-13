{
  description = "My NixOS Config";
  inputs = {

    # Nix ecosystem
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    systems.url = "github:nix-systems/default-linux";
    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Third party programs, packaged with nix
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-gaming = {
    #   # url = "github:fufexan/nix-gaming";
    #   url = "github:misterio77/nix-gaming";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    # nix-ld.url = "github:Mic92/nix-ld";
    # nix-ld.inputs.nixpkgs.follows = "nixpkgs";
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
    pkgsFor = lib.genAttrs (import systems) (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      }
    );
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});

    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs { inherit system; };
    # nixpkgs with deploy-rs overlay but force the nixpkgs package
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlay # or deploy-rs.overlays.default
        (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
      ];
    };
  in {
    inherit lib;

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    overlays = import ./overlays {inherit inputs outputs pkgs;};
    # hydraJobs = import ./hydra.nix {inherit inputs outputs;};

    # packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
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
      
      # msi-server
      msi-server = lib.nixosSystem {
        modules = [
          ./hosts/msi-server
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

      # VM for HackTheBox
      nixos-htb = lib.nixosSystem {
        modules = [
          ./hosts/nixos-htb
        ];
        specialArgs = {
          inherit inputs outputs;
        };
      };

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
      "adamr@nixos-htb" = lib.homeManagerConfiguration {
        modules = [
          ./home/adamr/nixos-htb.nix
          ./home/adamr/nixpkgs.nix
        ];
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs outputs;
        };
      };
      
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

    # Importing custom packages and nixos-generate configs
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;}) //
    {
      x86_64-linux = {
        install-iso = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "install-iso";
          modules = [
            {
              users.users.nixos = {
                initialHashedPassword = lib.mkForce "$y$j9T$tRAkzHi9kpFVhiUg21FIQ0$mkHVaqB1A/Seq4NfGnZaBswCQNWQ/8FWPrVKR5Qo7zD";
                openssh.authorizedKeys.keys = lib.splitString "\n" (builtins.readFile ./home/adamr/ssh.pub);
              };

              programs = {
                fish.enable = true;
              };
              security.pam.sshAgentAuth = {
                enable = true;
              };
              services.openssh = {
                enable = true;
                hostKeys = [
                  {
                    path = "/etc/ssh/ssh_host_ed25519_key";
                    type = "ed25519";
                  }
                ];
              };
              boot = {
                initrd = {
                  availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" "nvme" "usbhid" "usb_storage" ];
                  kernelModules = [ "kvm-intel" ];
                };
                kernelModules = [ "kvm-intel" ];
              };
            }
          ];
        };
      };
    };


    # Deploy-rs configs
    deploy = let 
      activate-nixos = deployPkgs.deploy-rs.lib.activate.nixos;
      activate-hm = deployPkgs.deploy-rs.lib.activate.home-manager;
    in {
      sshOpts = [ "-A" ];
      nodes = {
        #################
        # Adam Machines #
        #################
        msi-nixos = {
          hostname = "msi-nixos";
          profilesOrder = [ "system" ];
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.msi-nixos;
            };
            hm-adamr = {
              user = "adamr";
              path = activate-hm self.homeConfigurations."adamr@msi-nixos";
            };
          };
        };

        msi-server = {
          hostname = "msi-server";
          profilesOrder = [ "system" ];
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.msi-server;
            };
            hm-adamr = {
              user = "adamr";
              path = activate-hm self.homeConfigurations."adamr@msi-server";
            };
          };
        };

        vm-tests = {
          hostname = "vm-tests";
          profilesOrder = [ "system" ];
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.vm-tests;
            };
            hm-adamr = {
              user = "adamr";
              path = activate-hm self.homeConfigurations."adamr@vm-tests";
            };
          };
        };
        
        nixos-htb = {
          hostname = "nixos-htb";
          profilesOrder = [ "system" ];
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.nixos-htb;
            };
            hm-adamr = {
              user = "adamr";
              path = activate-hm self.homeConfigurations."adamr@nixos-htb";
            };
          };
        };

        # raspberrypi = {
        #   hostname = "raspberrypi";
        #   profilesOrder = [ "system" ];
        #   profiles = {
        #     system = {
        #       user = "root";
        #       path = activate-nixos self.nixosConfigurations.raspberrypi;
        #     };
        #     hm-adamr = {
        #       user = "adamr";
        #       path = activate-hm self.homeConfigurations."adamr@raspberrypi";
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
          profilesOrder = [ "system" ];
          profiles = {
            system = {
              user = "root";
              path = activate-nixos self.nixosConfigurations.danix;
            };
            hm-adamr = {
              user = "dani";
              path = activate-hm self.homeConfigurations."dani@danix";
            };
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
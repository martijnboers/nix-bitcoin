{
  description = ''
    A collection of Nix packages and NixOS modules for easily
    installing full-featured Bitcoin nodes with an emphasis on security.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    extra-container = {
      url = "github:erikarvstedt/extra-container/0.13";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # On these 32-bit platforms, Python pkg `pymemcache` 4.0.0 (required by
        # `joinmarket`) is broken:
        # "i686-linux"
        # "armv7l-linux"
      ];

      test = import ./test/tests.nix nixpkgs.lib self.nixosModules.default;
    in {
      lib = {
        mkNbPkgs = {
          system
          , pkgs ? nixpkgs.legacyPackages.${system}
          , pkgsUnstable ? nixpkgs-unstable.legacyPackages.${system}
        }:
          import ./pkgs { inherit pkgs pkgsUnstable; };

        test = {
          inherit (test) scenarios;
        };

        inherit supportedSystems;
      };

      overlays.default = final: prev: let
        nbPkgs = self.lib.mkNbPkgs { inherit (final) system; pkgs = final; };
      in removeAttrs nbPkgs [ "pinned" "nixops19_09" "krops" ];

      nixosModules.default = { config, ... }: {
        imports = [ ./modules/modules.nix ];

        config = {
          nix-bitcoin.pkgs = (self.lib.mkNbPkgs { inherit (config.nixpkgs) system; }).modulesPkgs;
        };
      };

      templates.default = {
        description = "Basic node template";
        path = ./examples/flakes;
      };

    } // (flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nbPkgs = self.lib.mkNbPkgs { inherit system pkgs; };
      in rec {
        packages = flake-utils.lib.flattenTree (removeAttrs nbPkgs [
          "fetchNodeModules"
          "krops"
          "modulesPkgs"
          "netns-exec"
          "nixops19_09"
          "pinned"
          "generate-secrets"
        ]) // {
          inherit (import ./examples/qemu-vm/minimal-vm.nix self pkgs system)
            # A simple demo VM.
            # See ./examples/flakes/flake.nix on how to use nix-bitcoin with flakes.
            runVM
            vm;
        };

        # Allow accessing the whole nested `nbPkgs` attrset (including `modulesPkgs`)
        # via this flake.
        # `packages` is not allowed to contain nested pkgs attrsets.
        legacyPackages =
          nbPkgs //
          (test.pkgs self pkgs) //
          {
            extra-container = self.inputs.extra-container.packages.${system}.default;
          };

        apps = rec {
          default = vm;

          # Run a basic nix-bitcoin node in a VM
          vm = {
            type = "app";
            program = toString packages.runVM;
          };
        };

        devShells.default = import ./dev/dev-env/dev-shell.nix pkgs;
      }
    ));
}

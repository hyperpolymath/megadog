{
  description = "MegaDog - Ethical merge game with Mandelbrot dogtags";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Pony language
    ponyc = {
      url = "github:ponylang/ponyup";
      flake = false;
    };

    # Nickel for configuration
    nickel = {
      url = "github:tweag/nickel";
    };

    # Vyper for smart contracts
    vyper = {
      url = "github:vyperlang/vyper";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, nickel, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = false;
        };

        # Pony compiler
        ponyc = pkgs.ponyc;

        # Kotlin for Android renderer
        kotlin = pkgs.kotlin;

        # Build tools
        buildInputs = with pkgs; [
          # Core languages
          ponyc
          kotlin
          gradle

          # Smart contracts
          # vyper  # Build from source below

          # Configuration
          nickel.packages.${system}.default
          cue
          dhall
          dhall-json

          # Container tooling (Podman, never Docker)
          podman
          buildah
          skopeo

          # Nix tooling
          nil
          nixpkgs-fmt

          # General utilities
          just
          jq
          yq-go
          ripgrep
          fd

          # Git tooling
          git
          git-lfs
          pre-commit

          # Documentation
          mdbook
          graphviz
          plantuml
        ];

        # Vyper from source (memory-safe Python alternative pending)
        # NOTE: Commented out - placeholder hash needs to be computed with:
        #   nix-prefetch-url --unpack https://github.com/vyperlang/vyper/archive/v0.3.10.tar.gz
        # vyperPkg = pkgs.python3Packages.buildPythonPackage rec {
        #   pname = "vyper";
        #   version = "0.3.10";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "vyperlang";
        #     repo = "vyper";
        #     rev = "v${version}";
        #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        #   };
        #   doCheck = false;
        # };

      in {
        # Development shell
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          shellHook = ''
            echo "MegaDog Development Environment (RSR Compliant)"
            echo "================================================"
            echo "Pony:    $(ponyc --version 2>/dev/null || echo 'not installed')"
            echo "Kotlin:  $(kotlin -version 2>&1 | head -1)"
            echo "Nickel:  $(nickel --version 2>/dev/null || echo 'available')"
            echo "Podman:  $(podman --version)"
            echo ""
            echo "Run 'just' to see available commands"
          '';

          # Environment variables
          MEGADOG_ENV = "development";
          CONTAINER_RUNTIME = "podman";
        };

        # Packages
        packages = {
          # Pony server
          megadog-server = pkgs.stdenv.mkDerivation {
            pname = "megadog-server";
            version = "0.1.0";
            src = ./server;

            buildInputs = [ ponyc ];

            buildPhase = ''
              ponyc -o $out/bin server
            '';

            installPhase = ''
              mkdir -p $out/bin
            '';
          };

          # Container image (Wolfi-based)
          megadog-container = pkgs.dockerTools.buildImage {
            name = "megadog-server";
            tag = "latest";

            copyToRoot = pkgs.buildEnv {
              name = "megadog-root";
              paths = [ self.packages.${system}.megadog-server ];
            };

            config = {
              Cmd = [ "/bin/megadog-server" ];
              ExposedPorts = {
                "8080/tcp" = {};
              };
            };
          };
        };

        # Apps
        apps = {
          default = {
            type = "app";
            program = "${self.packages.${system}.megadog-server}/bin/megadog-server";
          };
        };

        # Checks (run with `nix flake check`)
        checks = {
          # Format check
          format = pkgs.runCommand "format-check" {
            buildInputs = [ pkgs.nixpkgs-fmt ];
          } ''
            nixpkgs-fmt --check ${./.}/*.nix
            touch $out
          '';

          # Nickel config validation
          nickel-check = pkgs.runCommand "nickel-check" {
            buildInputs = [ nickel.packages.${system}.default ];
          } ''
            for f in ${./config}/*.ncl; do
              nickel typecheck "$f" || exit 1
            done
            touch $out
          '';
        };
      }
    );
}

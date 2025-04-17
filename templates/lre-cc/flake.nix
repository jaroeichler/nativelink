{
  description = "project-name";
  inputs = {
    flake-parts = {
      follows = "nativelink/flake-parts";
    };
    git-hooks = {
      follows = "nativelink/git-hooks";
    };
    nativelink = {
      url = "github:jaroeichler/nativelink/simplify-flake";
    };
    nixpkgs = {
      follows = "nativelink/nixpkgs";
    };
  };
  outputs = inputs @ {
    flake-parts,
    git-hooks,
    nativelink,
    nixpkgs,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        git-hooks.flakeModule
        nativelink.flakeModules.local-remote-execution
      ];

      perSystem = {
        config,
        pkgs,
        system,
        ...
      }: let
        bazel = pkgs.writeShellScriptBin "bazel" ''
          unset TMPDIR TMP
          exec ${pkgs.bazelisk}/bin/bazelisk "$@"
        '';
      in {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = [
            nativelink.overlays.lre
          ];
        };

        # Option from the nativelink flake module.
        local-remote-execution = {
          # Use the lre-cc environment from nativelink locally.
          inherit (pkgs.lre.lre-cc.meta) Env;
        };

        # Option from the git-hooks flake module.
        pre-commit.settings = {
          hooks = import ./pre-commit-hooks.nix {
            inherit pkgs;
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            # Development tools
            pkgs.git

            # Build dependencies
            bazel
            pkgs.lre.clang

            # Infrastructure
          ];
          shellHook = ''
            # Generate lre.bazelrc, which configures LRE toolchains.
            ${config.local-remote-execution.installationScript}
            # Generate .pre-commit-config.yaml symlink.
            ${config.pre-commit.installationScript}
          '';
        };
      };
    };
}

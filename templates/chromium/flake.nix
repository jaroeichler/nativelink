{
  description = "chromium";
  inputs = {
    depot-tools = {
      url = "git+https://chromium.googlesource.com/chromium/tools/depot_tools";
      flake = false;
    };
    flake-parts = {
      follows = "nativelink/flake-parts";
    };
    git-hooks = {
      follows = "nativelink/git-hooks";
    };
    nativelink = {
      url = "github:TraceMachina/nativelink";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      follows = "nativelink/nix2container";
    };
    nixpkgs = {
      follows = "nativelink/nixpkgs";
    };
  };
  outputs = inputs @ {
    depot-tools,
    flake-parts,
    git-hooks,
    nativelink,
    nix2container,
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
      ];

      perSystem = {
        config,
        lib,
        pkgs,
        system,
        ...
      }: let
        cred-helper = pkgs.writeShellScriptBin "cred-helper" ''
          if [ -z "''${X_NATIVELINK_API_KEY}" ]; then
            echo "Error: X_NATIVELINK_API_KEY environment variable is not set" >&2
            exit 1
          fi

          cat <<EOF
          {
            "headers": {
              "x-nativelink-api-key": [ "''${X_NATIVELINK_API_KEY}" ]
            }
          }
          EOF
        '';

        inherit (nix2container.packages.${system}.nix2container) pullImage;
        inherit (nix2container.packages.${system}.nix2container) buildImage;
        basic-cas = pkgs.writeText "basic_cas.json5" (builtins.readFile ./basic_cas.json5);
        chromium-worker = buildImage {
          name = "chromium-worker";
          tag = "latest";
          fromImage = pullImage {
            arch = "amd64";
            imageDigest = "sha256:26de99218a1a8b527d4840490bcbf1690ee0b55c84316300b60776e6b3a03fe1";
            imageName = "gcr.io/chops-public-images-prod/rbe/siso-chromium/linux";
            os = "linux";
            sha256 = "sha256-v2wctuZStb6eexcmJdkxKcGHjRk2LuZwyJvi/BerMyw=";
            tlsVerify = true;
          };
          config = {
            entrypoint = [
              "${nativelink.packages.${system}.default}/bin/nativelink"
              "${basic-cas}"
            ];
          };
        };

        # TODO(jaroeichler): Clean this up a bit if we don't build an image
        # with these.
        buildInputs = with pkgs; [
          alsa-lib # libasound.so.2
          at-spi2-atk # libatk-1.0.so.0
          bash
          bzip2
          cacert
          cairo # libcairo.so.2
          clang
          coreutils
          cups
          curl
          dbus # libdbus-1.so.3
          diffutils
          expat
          file
          findutils
          fuse
          gawk
          getent
          git
          glib # glib compilers
          glib.out # libglib-2.0.so.0
          glibcLocales
          gnugrep
          gnused
          gnutar
          google-cloud-sdk
          gperf
          gzip
          less
          libcxx
          libdrm # libdrm.so.2
          libgcc
          libxkbcommon # libxkbcommon.so.0
          mesa # libgbm.so.1
          nspr
          nss # libnss3.so
          pango # libpango-1.0.so.0
          pkg-config
          python313
          su
          systemd
          wayland-scanner
          which
          xorg.libX11.dev # libX11.so.6
          xorg.libXcomposite # libXcomposite.so.1
          xorg.libXdamage # libXdamage.so.1
          xorg.libXext # libXext.so.6
          xorg.libXfixes # libXfixes.so.3
          xorg.libXrandr # libXrandr.so.2
          xorg.libXtst # libXtst.so.6
          xorg.libxcb # libxcb.so.1
          xorg.xdpyinfo
          xz
          zlib
        ];
      in {
        pre-commit.settings = {
          hooks = import ./pre-commit-hooks.nix {inherit pkgs;};
        };

        packages = {
          inherit chromium-worker;
        };

        devShells.default = pkgs.mkShell {
          packages = buildInputs;
          shellHook = ''
            # Generate .pre-commit-config.yaml symlink.
            ${config.pre-commit.installationScript}

            # TODO(jaroeichler): Make this less hacky and don't use `cp -f`.
            # Note that some Python scripts need write permissions, so we can't
            # just add `${depot-tools}` to path.
            cp -rf ${depot-tools} /tmp/depot-tools
            chmod -R u+w /tmp/depot-tools

            export DEPOT_TOOLS_UPDATE=0
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH"
            export PATH="/tmp/depot-tools:$PATH"
            export SISO_CREDENTIAL_HELPER=${cred-helper}/bin/cred-helper
          '';
        };
      };
    };
}

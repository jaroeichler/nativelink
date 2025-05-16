{
  description = "chromium";
  inputs = {
    flake-parts = {
      follows = "nativelink/flake-parts";
    };
    git-hooks = {
      follows = "nativelink/git-hooks";
    };
    nativelink = {
      url = "github:TraceMachina/nativelink";
    };
    nixpkgs = {
      follows = "nativelink/nixpkgs";
    };
  };
  outputs = inputs @ {
    flake-parts,
    git-hooks,
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

        # TODO(jaroeichler): Split into worker and client inputs.
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

        devShells.default = pkgs.mkShell {
          packages = buildInputs;
          shellHook = ''
            # Generate .pre-commit-config.yaml symlink.
            ${config.pre-commit.installationScript}

            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH"
            export PATH="$(pwd)/depot_tools:$PATH"
            export SISO_CREDENTIAL_HELPER=${cred-helper}/bin/cred-helper
          '';
        };
      };
    };
}

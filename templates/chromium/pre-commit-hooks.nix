{pkgs, ...}: let
  excludes = [];
in {
  # General
  check-case-conflicts = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  detect-private-keys = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  end-of-file-fixer = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  fix-byte-order-marker = {
    enable = true;
    inherit excludes;
  };
  forbid-binary-files = {
    enable = true;
    entry = let
      script = pkgs.writeShellScriptBin "forbid-binary-files" ''
        set -eu

        if [ $# -gt 0 ]; then
          for filename in "''${@}"; do
            printf "[\033[31mERROR\033[0m] Found binary file: ''${filename}"
          done
          exit 1
        fi
      '';
    in "${script}/bin/forbid-binary-files";
    inherit excludes;
    name = "forbid-binary-files";
    types = ["binary"];
  };
  mixed-line-endings = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };
  trim-trailing-whitespace = {
    enable = true;
    inherit excludes;
    types = ["text"];
  };

  # Nix
  alejandra.enable = true;
  deadnix.enable = true;
  statix.enable = true;
}

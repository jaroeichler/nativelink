{pkgs, ...}: let
  excludes = [];
in {
  # General
  check-case-conflict = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/check-case-conflict";
    inherit excludes;
    name = "check-case-conflict";
    types = ["text"];
  };
  detect-private-key = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/detect-private-key";
    inherit excludes;
    name = "detect-private-key";
    types = ["text"];
  };
  end-of-file-fixer = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/end-of-file-fixer";
    inherit excludes;
    name = "end-of-file-fixer";
    types = ["text"];
  };
  fix-byte-order-marker = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/fix-byte-order-marker";
    inherit excludes;
    name = "fix-byte-order-marker";
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
  mixed-line-ending = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/mixed-line-ending";
    inherit excludes;
    name = "mixed-line-ending";
    types = ["text"];
  };
  trailing-whitespace-fixer = {
    enable = true;
    entry = "${pkgs.python312Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
    inherit excludes;
    name = "trailing-whitespace";
    types = ["text"];
  };

  # C++
  clang-format18 = {
    enable = true;
    name = "clang-format";
    types_or = ["c" "c++"];
    entry = "${pkgs.llvmPackages_18.libclang}/bin/clang-format";
  };

  # Nix
  alejandra.enable = true;
  deadnix.enable = true;
  statix.enable = true;

  # Starlark
  bazel-buildifier-format = {
    enable = true;
    entry = "${pkgs.bazel-buildtools}/bin/buildifier -lint=fix";
    name = "buildifier format";
    types = ["bazel"];
  };
  bazel-buildifier-lint = {
    enable = true;
    entry = "${pkgs.bazel-buildtools}/bin/buildifier -lint=warn";
    excludes = ["local-remote-execution/generated-cc/cc/cc_toolchain_config.bzl"];
    name = "buildifier lint";
    types = ["bazel"];
  };
}

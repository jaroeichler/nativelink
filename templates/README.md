Get started with NativeLink.

Install `Nix` with `flakes` enabled. Initialize the template:
```
nix flake init -t github:TraceMachina/nativelink#lre-cc
```
Enter the Nix environment with `nix develop`.
Optionally install `direnv` and create
```.envrc
use flake
```
to automatically enter the development environment.

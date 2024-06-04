{
  inputs = {
    crane = {
      url = "github:ipetkov/crane";
    };
    nixpkgs  = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
      flake = true;
      follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay, crane }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          # this is how we tell crain to use our toolchain!
          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
          # cf. https://crane.dev/API.html#libcleancargosource
          src = craneLib.cleanCargoSource ./.;
          # as before
          nativeBuildInputs = with pkgs; [ rustToolchain pkg-config ];
          buildInputs = with pkgs; [ openssl sqlite ];
          # because we'll use it for both `cargoArtifacts` and `bin`
          commonArgs = {
            inherit src buildInputs nativeBuildInputs;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          # remember, `set1 // set2` does shallow merge:
          bin = craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
          });
        in
        with pkgs;
        {
          packages = {
            # that way we can build `bin` specifically,
            # but it's also the default.
            inherit bin;
            default = bin;
          };
          devShells.default = mkShell {
            # instead of passing `buildInputs` / `nativeBuildInputs`,
            # we refer to an existing derivation here
            inputsFrom = [ bin ];
          };
        }
      );
}

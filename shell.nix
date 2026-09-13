let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };

  # Temporary: nixpkgs only ships zola 0.23.4. The upstream bump
  # (NixOS/nixpkgs#562808, zola 0.23.4 -> 0.23.6) is automated; delete this
  # override once it merges.
  zola = pkgs.stdenv.mkDerivation {
    pname = "zola";
    version = "0.23.6";
    src = pkgs.fetchurl {
      url = "https://github.com/getzola/zola/releases/download/v0.23.6/zola-v0.23.6-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "8f5132b3522412d04e395e0b25f6d68613ad272a873e54a2b3ebf664873024a4";
    };
    dontConfigure = true;
    dontBuild = true;
    unpackPhase = ''
      tar -xzf "$src"
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/man/man1
      install -m755 zola $out/bin/zola
      install -m644 artifacts/*.1 $out/share/man/man1/
      runHook postInstall
    '';
    meta.mainProgram = "zola";
  };
in

pkgs.mkShellNoCC {
  packages = with pkgs; [
    just
    zola
    cowsay
    lolcat
  ];

  GREETING = "Run 'just' to build and serve the site.";

  shellHook = ''
    echo $GREETING | cowsay | lolcat
  '';
}
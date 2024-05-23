let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
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
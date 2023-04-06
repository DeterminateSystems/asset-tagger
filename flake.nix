{
  description = "assets";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self
    , nixpkgs
    , ...
    } @ inputs:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "asset";

        buildInputs = with pkgs; [
          imagemagick
          barcode
          python3.pkgs.brother-ql
          qrcode
          jq
          shellcheck
          shfmt
        ];
      };

      packages.x86_64-linux.default = pkgs.resholve.writeScript "name" {
        inputs = with pkgs; [ curl jq coreutils qrcode imagemagick 
          python3.pkgs.brother-ql ];
        interpreter = "${pkgs.bash}/bin/bash";
        execer = [
  "cannot:${pkgs.python3.pkgs.brother-ql}/bin/brother_ql"
        ];
      } (builtins.replaceStrings ["logo-v2.svg" ] [ "${./logo-v2.svg}" ] (builtins.readFile ./make.sh));
    };
}

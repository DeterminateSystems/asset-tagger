{
  description = "assets";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }@inputs:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
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

      packages.x86_64-linux.default = pkgs.resholve.mkDerivation
        {
          pname = "asset-label-printer";
          version = "main";

          src = ./.;

          dontConfigure = true;
          dontBuild = true;

          patchPhase = ''
            substituteInPlace \
              ./*.sh \
              --replace "logo-v2.svg" "${./logo-v2.svg}" \
              --replace "FreeMono" "${pkgs.freefont_ttf}/share/fonts/truetype/FreeMono.ttf" \
              --replace "./make.sh" "asset-label-print"
          '';

          installPhase = ''
            install -D make.sh $out/bin/asset-label-print
            install -D print-all.sh $out/bin/asset-labels-print-queued
          '';

          solutions = {
            default = {
              scripts = [ "bin/asset-labels-print-queued" "bin/asset-label-print" ];
              inputs = with pkgs;
                [
                  curl
                  jq
                  coreutils
                  qrcode
                  imagemagick
                  python3.pkgs.brother-ql
                  "bin"
                ];
              fix = {
                "asset-label-print" = [ "${placeholder "out"}/bin/asset-label-print" ];
              };
              interpreter = "${pkgs.bash}/bin/bash";
              execer = [
                "cannot:${pkgs.python3.pkgs.brother-ql}/bin/brother_ql"
                "cannot:bin/asset-label-print"
              ];
            };
          };
        };
    };
}

{
  description = "(Flake for Apache Tika server)";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-20.09";
  # Upstream source tree(s).

  outputs = { self, nixpkgs}:
    let

      # Generate a user-friendly version numer.
      version = "1.26";
      # System types to support.
      supportedSystems = [ "x86_64-linux" ];
      
      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        tika-server = with final; stdenv.mkDerivation rec {
          name = "tika-server-${version}";

          src = fetchurl {
            url = https://archive.apache.org/dist/tika/tika-server-1.26.jar;
            sha256 ="sha256-GLXsW4p/gKPOJTz5PF6l8DGjwXvIPoirDSmlFujnPZU=";
          };

          dontUnpack = true;

          buildInputs =with nixpkgs; [
            jdk
            tesseract
            gdal
            gnupg
          ];


          nativeBuildInputs = [
            makeWrapper
          ];


          installPhase = ''
          echo "Installing.. "
            mkdir -pv $out/share/java $out/bin
            ls -l ${src}
          cp ${src} $out/share/java/tika-server-1.27.jar
          makeWrapper ${jre}/bin/java $out/bin/tika-server \
            --add-flags "-jar $out/share/java/tika-server-1.27.jar" \
            --set _JAVA_OPTIONS '-Dawt.useSystemAAFontSettings=on' \
            --set _JAVA_AWT_WM_NONREPARENTING 1
            '';


          meta = {
            homepage = "https://www.gnu.org/software/hello/";
            description = "A program to show a familiar, friendly greeting";
          };
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) tika-server;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.tika-server);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.tika-server={config, nixpkgs, lib,...}:with lib; {

                options = {

                  services.tika-server = {

                    enable = mkOption {
                      type = types.bool;
                      default = false;
                      description = ''
                      tika server
                      '';
                    };
                  };

                };


                ###### implementation

                config = mkIf config.services.tika-server.enable {

                  systemd.services.tika-server = {
                    description = "Tika Server";
                    serviceConfig = {
                      ExecStart = ${self.defaultPackage}.${system}.tika-server/bin/tika-server;
                      
                    };
                  };
                };



         
         };

      # Tests run by 'nix flake check' and by Hydra.
    /*  checks = forAllSystems (system: {
        inherit (self.packages.${system}) hello;

        # Additional tests, if applicable.
        test =
          with nixpkgsFor.${system};
          stdenv.mkDerivation {
            name = "hello-test-${version}";

            buildInputs = [ hello ];

            unpackPhase = "true";

            buildPhase = ''
              echo 'running some integration tests'
              [[ $(hello) = 'Hello, world!' ]]
            '';

            installPhase = "mkdir -p $out";
          };

        # A VM test of the NixOS module.
        vmTest =
          with import (nixpkgs + "/nixos/lib/testing-python.nix") {
            inherit system;
          };

          makeTest {
            nodes = {
              client = { ... }: {
                imports = [ self.nixosModules.hello ];
              };
            };

            testScript =
              ''
                start_all()
                client.wait_for_unit("multi-user.target")
                client.succeed("hello")
              '';
          };
          });
          */

    };
}

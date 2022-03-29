{
  description = "An over-engineered Hello World in bash";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
  inputs.vt-colors.url = "path:/home/spacecadet/Documents/projects/vt-colors";

  outputs = { self, nixpkgs, vt-colors }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
      color_table = vt-colors.colors_raw;
    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        sway-rename-workspace = with final; stdenv.mkDerivation rec {
          name = "sway-rename-workspace-${version}";
          unpackPhase = ":";
          buildPhase =
            ''
              cat > sway-rename-workspace <<EOF
              #!${prev.zsh}/bin/zsh
              # Script that renames current workspace from (index) to (index): name
              # Also has some icons to suggest

              # Generate the new PATH by hand, declaring dependencies
              # There was an easier way to do this...
              export PATH=${prev.lib.concatStringsSep ":" (map (x: x+"/bin") [ prev.bemenu prev.jq prev.sway] )}:$PATH
              EOF
              # A bit hacky, but better than the escape headache
              cat ${self}/scripts/rename-workspace | sed "s/TITLE_FOREGROUND_COLOR/${color_table.dark-purple}/" | sed "s/HIGHLIGHTED_FOREGROUND_COLOR/${color_table.light-purple}/" >> sway-rename-workspace
              chmod +x sway-rename-workspace
            '';

          installPhase =
            ''
              mkdir -p $out/bin
              cp sway-rename-workspace $out/bin/
            '';
        };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) sway-rename-workspace;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.sway-rename-workspace);
    };
}

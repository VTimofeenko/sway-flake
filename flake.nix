{
  description = "Nix flake that contains my sway config";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
  inputs.vt-colors.url = "path:/home/spacecadet/Documents/projects/vt-colors";
  inputs.home-manager.url = "github:rycee/home-manager/release-21.11";

  outputs = { self, nixpkgs, vt-colors, home-manager }:
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
      # Overlay containing custom packages and scripts
      overlay = final: prev: {
        # Script that renames works
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

              # Declare colors, they will be used in the script itself
              TITLE_FOREGROUND_COLOR="${color_table.dark-purple}"
              HIGHLIGHTED_FOREGROUND_COLOR="${color_table.light-purple}"
              EOF
              # A bit hacky, but better than the escape headache
              cat ${self}/scripts/rename-workspace >> sway-rename-workspace
              chmod +x sway-rename-workspace
            '';
          installPhase =
            ''
              mkdir -p $out/bin
              cp sway-rename-workspace $out/bin/
            '';
        };
      };
      nixosModule = import ./sway.nix;
      nixosModules.system = import ./system_module.nix;
    };
}

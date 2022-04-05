{
  description = "Nix flake that contains my sway config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    vt-colors.url = "path:/home/spacecadet/Documents/projects/vt-colors";
    home-manager.url = "github:rycee/home-manager/release-21.11";
    # Colors
    base16.url = "github:SenchoPens/base16.nix";
    base16.inputs.nixpkgs.follows = "nixpkgs";

    base16-atlas-scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };
    base16-mako = {
      url = "github:stacyharper/base16-mako";
      flake = false;
    };
    /* Not needed, very little in the repo */
    /* base16- = { */
    /*   url = "github:rkubosz/base16-sway"; */
    /*   flake = false; */
    /* }; */
  };


  outputs = { self, nixpkgs, vt-colors, home-manager, ... }@inputs:
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
        # Script that renames workspaces
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
      /* Note:
      To import this module, it's necessary to use something like
      home-manager.users.username = {this_flake}.nixosModule { inherit vt-colors pkgs ; inherit (pkgs) lib; };
      */
      # nixosModule = import ./sway.nix { inherit (inputs) base16 base16-atlas-scheme; };
      nixosModule = import ./sway.nix inputs;

      nixosModules.system = import ./system_module.nix;
    };
}

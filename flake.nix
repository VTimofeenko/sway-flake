{
  description = "Nix flake that contains my sway config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
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
    base16-waybar = {
      url = "github:mnussbaum/base16-waybar";
      flake = false;
    };
    /* Not needed, very little in the repo */
    /* base16- = { */
    /*   url = "github:rkubosz/base16-sway"; */
    /*   flake = false; */
    /* }; */
  };


  outputs = { self, nixpkgs, home-manager, ... }@inputs:
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
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });
    in
    {
      packages = forAllSystems (system:
        import ./overlay {
          pkgs = import nixpkgs { inherit system; };
        });
      apps = forAllSystems (system:
        rec {
          sway-rename-workspace = {
            type = "app";
            program = "${self.packages.${system}.sway-rename-workspace}/bin/sway-rename-workspace";
          };
          scratchpad-terminal = {
            type = "app";
            program = "${self.packages.${system}.scratchpad-terminal}/bin/scratchpad-terminal";
          };
          default = sway-rename-workspace;
        }
      );
      overlays.default = final: prev:
        let
          localPkgs = import ./overlay { pkgs = final; };
        in
        {
          inherit (localPkgs) sway-rename-workspace scratchpad-terminal;
        };

      nixosModule = import ./sway.nix inputs;

      nixosModules.system = import ./system_module.nix;
    };
}

{
  description = "Nix flake that contains my sway config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    home-manager.url = "github:rycee/home-manager/release-22.11";
    # Colors
    base16 = {
      url = "github:SenchoPens/base16.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Colorscheme. Note the variable "schemeName" below. It also needs to be changed to point at the proper yaml file.
    color-scheme = {
      url = "github:ajlende/base16-atlas-scheme";
      flake = false;
    };
    # Templates for services
    base16-mako = {
      url = "github:stacyharper/base16-mako";
      flake = false;
    };
    base16-waybar = {
      url = "github:mnussbaum/base16-waybar";
      flake = false;
    };
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      schemeName = "atlas";

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
          sway-change-workspace-number = {
            type = "app";
            program = "${self.packages.${system}.sway-change-workspace-number}/bin/sway-change-workspace-number";
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
          inherit (localPkgs) sway-rename-workspace sway-change-workspace-number scratchpad-terminal;
        };

      nixosModules = {
        default = import ./modules inputs schemeName;
        system = import ./modules/system inputs;
      };
    };
}

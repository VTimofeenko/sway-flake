inputs: schemeName: { config, lib, pkgs, ... }:
let
  mkTemplate = (inputs.base16.outputs.lib { inherit pkgs lib; }).mkSchemeAttrs "${inputs.color-scheme}/${schemeName}.yaml";
  makoTemplate = (inputs.base16.outputs.lib { inherit pkgs lib; }).mkSchemeAttrs "${inputs.color-scheme}/${schemeName}.yaml" inputs.base16-mako;
  waybarTemplate = mkTemplate inputs.base16-waybar;

  colorScheme = (import ./colorscheme inputs.base16 inputs.color-scheme schemeName);
  makoModule = (import ./mako makoTemplate);
  waybarModule = (import ./waybar waybarTemplate);
in
{
  imports = [
    ./sway
    ./gtk
    ./base
    colorScheme
    makoModule
    waybarModule
    ./flameshot
  ];
}

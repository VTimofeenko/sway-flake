inputs: { pkgs, lib, ... }:

let
  template = (inputs.base16.outputs.lib {inherit pkgs lib;}).mkSchemeAttrs
    # The color scheme
    "${inputs.base16-atlas-scheme}/atlas.yaml"
    # The template
    inputs.base16-mako;
in
{
  programs.mako = {
    enable = true;
    defaultTimeout = 5000;
    # backgroundColor = vt-colors.colors_raw.light-purple;
    extraConfig = builtins.readFile (template);
  };
}

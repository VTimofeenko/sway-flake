base16: scheme-input: schemeName: { config, lib, pkgs, ... }:
let
  scheme = (base16.outputs.lib { inherit pkgs lib; }).mkSchemeAttrs "${scheme-input}/${schemeName}.yaml";
in
with lib;
{
  options.vt-sway = {
    semanticColors = {
      defaultFg = mkOption {
        type = types.str;
        description = "Hext color for default foreground";
        default = scheme.base07;
      };
      defaultBg = mkOption {
        type = types.str;
        description = "Hext color for default background";
        default = scheme.base00;
      };
      alarm = mkOption {
        type = types.str;
        description = "Hex color to be used for something urgent";
        default = scheme.base08;
      };
      warning = mkOption {
        type = types.str;
        description = "Hex color to be used for something not very urgent but requiring attention";
        default = scheme.base0A;
      };
      ok = mkOption {
        type = types.str;
        description = "Hex color to be used for something that is OK";
        default = scheme.base0B;
      };
      highlight = mkOption {
        type = types.str;
        description = "Hex color to be used for highlights";
        default = scheme.base0C;
      };
      selector = mkOption {
        type = types.str;
        description = "Hex color to be used for showing a selected element. Very close in meaning to highlight";
        default = scheme.base0D;
      };
      otherSelector = mkOption {
        type = types.str;
        description = "Hex color to be used for showing a selected element if selector is already used. Very close in meaning to highlight";
        default = scheme.base0E;
      };
    };
    colorScheme = mkOption {
      description = "Base16 colorscheme to be used. See https://github.com/SenchoPens/base16.nix for schema";
      type = types.attrs;
      default = scheme;
    };
  };
}

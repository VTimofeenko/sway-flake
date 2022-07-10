{ config, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./custom-target.nix
  ];
  options.vt-sway = {
    enableBrightness = mkEnableOption "enable brightness controls";
    customTarget = rec {
      name = mkOption {
        description = "Name of custom target to bind user services to";
        type = types.str;
        default = "sway-wm";
      };
      fullname = mkOption {
        description = "Full name of the target with systemd postfix";
        type = types.str;
        default = "sway-wm.target";
      };
      desc = mkOption rec {
        description = "Description of the service";
        type = types.str;
        default = description;
      };
    };
  };
}

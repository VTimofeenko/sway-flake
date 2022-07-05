# File containing configs for different modes
# The resize mode is overridden to show a help menu
{ pkgs, lib, config, ... }:
let
  helpers = rec {
    normalModeCmd = "exec pkill yad; mode default";
    mkHelpNotificationText = mode_def: lib.concatStringsSep "\\n" (lib.mapAttrsToList (name: value: "${name}: ${value}") (lib.filterAttrs (name: value: value != normalModeCmd) mode_def.mode."${mode_def.name}"));
    showHelpNotification = mode_def: "exec --no-startup-id ${pkgs.yad}/bin/yad --html --no-buttons --text \"${mkHelpNotificationText mode_def}\"";
  };

  inherit (config.vt-sway) customTarget;
  modes = {
    exit_ctl = {
      name = "exit_ctl";
      mode = {
        exit_ctl = {
          "l" = "exec systemctl --user stop ${customTarget.fullname};exec swaymsg exit";
          "s" = "exec systemctl suspend";
          "Shift+s" = "exec systemctl shutdown";
          "Shift+r" = "exec systemctl reboot";
          "Return" = helpers.normalModeCmd;
          "Escape" = helpers.normalModeCmd;
        };
      };
    };
    resize = {
      name = "resize";
      mode = {
        resize = {
          "h" = "resize shrink width 10 px";
          "j" = "resize grow height 10 px";
          "k" = "resize shrink height 10 px";
          "l" = "resize grow width 10 px";
          "Shift+h" = "resize shrink width 100 px";
          "Shift+j" = "resize grow height 100 px";
          "Shift+k" = "resize shrink height 100 px";
          "Shift+l" = "resize grow width 100 px";
          "Return" = helpers.normalModeCmd;
          "Escape" = helpers.normalModeCmd;
        };
      };
    };
  };
in
{
  wayland.windowManager.sway.config = {
    modes = modes.resize.mode // modes.exit_ctl.mode;
    keybindings = lib.mkOptionDefault (
      let
        modifier = config.wayland.windowManager.sway.config.modifier;
      in
      with modes;
      {
        "${modifier}+Shift+r" = "${helpers.showHelpNotification resize}; mode ${resize.name}";
        "${modifier}+backslash" = ''${helpers.showHelpNotification exit_ctl}; mode ${exit_ctl.name}'';
      }
    );
  };
}

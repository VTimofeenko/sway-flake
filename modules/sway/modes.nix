# File containing configs for different modes
# The resize mode is overridden to show a help menu
{ pkgs, lib, config, ... }:
let
  helpers = rec {
    normalModeCmd = "exec pkill yad; mode default";
    /*
      Constructs attrset that the other functions expect
    */
    mkBinding = mapping: _description: {
      description = _description;
      action = mapping;
    };
    /*
      Binds multiple keys to same action
    */
    multiMap = mapping: _description: key_list:
      builtins.listToAttrs (map
        (_:
          {
            name = _;
            value = {
              description = _description;
              action = mapping;
            };
          }
        )
        key_list);
    mkHelpNotificationText = mode_def: lib.concatStringsSep "\\n" (lib.mapAttrsToList (name: value: "${name}: ${value.description}") (lib.filterAttrs (name: value: value.action != normalModeCmd) mode_def.mode."${mode_def.name}"));
    showHelpNotification = mode_def: "exec --no-startup-id ${pkgs.yad}/bin/yad --html --no-buttons --text \"${mkHelpNotificationText mode_def}\"";

    /*
      Function that removes the descriptions from the mode making it easier to append
    */
    flattenMode = mode: lib.mapAttrs (name: value: value.action) mode;
    normalModeBindings = multiMap normalModeCmd "Back to normal mode" [ "Return" "Escape" ];
  };

  overlay = (import ../../overlay) (pkgs);

  # Color-aware wrapper around the sway-rename-workspace
  sway-rename-workspace-wrapped = pkgs.writeShellScript "sway-rename-workspace-wrapped" ''
    export TITLE_FOREGROUND_COLOR="#${semanticColors.defaultBg}"
    export TITLE_BACKGROUND_COLOR="#${semanticColors.otherSelector}"
    export HIGHLIGHTED_FOREGROUND_COLOR="#${semanticColors.otherSelector}"
    ${overlay.sway-rename-workspace}/bin/sway-rename-workspace
  '';
  sway-change-workspace-number-wrapped = pkgs.writeShellScript "sway-change-workspace-number-wrapped" ''
    export TITLE_FOREGROUND_COLOR="#${semanticColors.defaultBg}"
    export TITLE_BACKGROUND_COLOR="#${semanticColors.otherSelector}"
    export HIGHLIGHTED_FOREGROUND_COLOR="#${semanticColors.otherSelector}"
    ${overlay.sway-change-workspace-number}/bin/sway-change-workspace-number
  '';

  inherit (config.vt-sway) customTarget semanticColors;
  modes = {
    exit_ctl = {
      name = "exit_ctl";
      mode = with helpers; {
        exit_ctl = {
          "l" = mkBinding "exec systemctl --user stop ${customTarget.fullname};exec swaymsg exit" "Log out of sway";
          "s" = mkBinding "exec systemctl suspend" "Suspend";
          "Shift+s" = mkBinding "exec systemctl shutdown" "Shutdown";
          "r" = mkBinding "exec systemctl reboot" "Reboot";
        } // normalModeBindings;
      };
    };
    resize = {
      name = "resize";
      mode = {
        resize = with helpers; {
          "h" = mkBinding "resize shrink width 10 px" "Shrink width 10 px";
          "j" = mkBinding "resize shrink height 10 px" "Shrink height 10 px";
          "k" = mkBinding "resize grow height 10 px" "Grow height 10 px";
          "l" = mkBinding "resize grow width 10 px" "Grow width 10 px";
          "Shift+h" = mkBinding "resize shrink width 100 px" "Shrink width 100 px";
          "Shift+j" = mkBinding "resize shrink height 100 px" "Shrink height 100 px";
          "Shift+k" = mkBinding "resize grow height 100 px" "Grow height 100 px";
          "Shift+l" = mkBinding "resize grow width 100 px" "Grow width 100 px";
        } // normalModeBindings;
      };
    };
    workspace_edit = {
      name = "workspace_edit";
      mode = with helpers; {
        workspace_edit = {
          "r" = mkBinding "exec --no-startup-id ${sway-rename-workspace-wrapped}; ${normalModeCmd}" "Rename workspace";
          "n" = mkBinding "exec --no-startup-id ${sway-change-workspace-number-wrapped}; ${normalModeCmd}" "Renumber workspace";
        } // normalModeBindings;
      };
    };
    sound_ctl = {
      name = "sound_ctl";
      mode = with helpers; {
        sound_ctl = { }
          /* Silence the output */
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle" "Toggle silence the output" [ "F1" "s" "XF86AudioMute" ]
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle" "Toggle mute the microphone" [ "m" "XF86AudioMicMute" ]
          /* Add lower/raise volume mappings */
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%" "Volume up 10%" [ "F2" "XF86AudioLowerVolume" ]
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%" "Volume down 10%" [ "F3" "XF86AudioRaiseVolume" ]
          // normalModeBindings;
      };
    };
  };
in
{
  wayland.windowManager.sway.config =
    let
      mkAppendableMode = mode_name: { ${mode_name} = helpers.flattenMode modes.${mode_name}.mode.${mode_name}; };
    in
    {
      modes = (mkAppendableMode "resize") // (mkAppendableMode "exit_ctl") // (mkAppendableMode "sound_ctl") // (mkAppendableMode "workspace_edit");
      keybindings = lib.mkOptionDefault (
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          mkShowHelpSwitchMode = mode: "${helpers.showHelpNotification mode}; mode ${mode.name}";
        in
        with modes;
        {
          "${modifier}+Shift+r" = "${helpers.showHelpNotification resize}; mode ${resize.name}";
          "${modifier}+backslash" = ''${helpers.showHelpNotification exit_ctl}; mode ${exit_ctl.name}'';
          "${modifier}+Ctrl+s" = (mkShowHelpSwitchMode sound_ctl);
          "${modifier}+Ctrl+w" = (mkShowHelpSwitchMode workspace_edit);
        }
      );
    };
}

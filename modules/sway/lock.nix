# File that defines how the workstation is locked
# Describes swaylock and swayidle behavior

{ pkgs, lib, config, ... }:
let
  inherit (config.vt-sway) customTarget;
  /*
    -f: daemonize
    -F: show failed attempts
    -k: show keyboard layout
    -c: color
  */
  lockCmd = "${pkgs.sway}/bin/swaymsg input '*' xkb_switch_layout 0 && ${pkgs.swaylock}/bin/swaylock -fF -k -c 000000";
in
{
  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault (
    {
      "${config.wayland.windowManager.sway.config.modifier}+Ctrl+q" = "exec ${lockCmd}";
    }
  );
  systemd.user.services = {
    swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        Documentation = [ "man:swayidle(1)" ];
        PartOf = [ "${customTarget.fullname}" ];
        BindsTo = [ "${customTarget.fullname}" ];
      };
      Install = {
        WantedBy = [ "${customTarget.fullname}" ];
      };
      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 600 '${lockCmd}' \
            timeout 600 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            before-sleep '${lockCmd}'
        '';
      };
    };
  };
  /* services.swayidle = {
    enable = true;
    events = [
    { event = "before-sleep"; command = "${lock_command}"; }
    { event = "lock"; command = "lock"; }
    { event = "after-resume"; command = "${pkgs.sway}/bin/swaymsg 'output * dpms on'"; }

    ];
    timeouts = [
    { timout = 600; command = "${lock_command}"; }
    { timout = 1200; command = "${pkgs.sway}/bin/swaymsg 'output * dpms off'"; }
    ];
    };
  */
}

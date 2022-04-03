{ pkgs, lib, ... }:

let
  # -f: daemonize
  # -F: show failed attempts
  # -k: show keyboard layout
  # -c: color
  lock_command = "${pkgs.swaylock}/bin/swaylock -fF -k -c 000000";
  my_modifier = "Mod4";
in
{
  # These options are taken from https://nix-community.github.io/home-manager/options.html
  wayland.windowManager.sway = {
    enable = true;
    # Assign windows to workspaces
    config = {
      assigns = {
        "mail" = [{ class = "^Thunderbird$"; }];
      };
      /* # bars = {}; # TODO */
      /* # bindkeysToCode = true; # TODO */
      /* colors = {};  # TODO */
      # Criteria for floating windows
      floating.criteria = [
        { class = "^Thunderbird$"; title=".* Reminder.*"; }
        { class = "Pavucontrol"; }
        { class = "Steam"; title="Friends List";}
      ];
      gaps.smartBorders = "on";
      # Input configuration
      input = {
        "type:keyboard" = {
          xkb_layout = "us,ru";
          xkb_options = "grp:win_space_toggle";
        };
        "type:touchpad" = {
          tap = "enabled";
          pointer_accel = "0.4";
        };
      };
      # Output configuration
      # TODO: make better
      output = {
        "eDP-1"= { "scale" = "1"; };
      };
      # Custom keybindings
      keybindings = let modifier = my_modifier; in lib.mkOptionDefault
      {
        /* Launcher */
        "${modifier}+shift+r" = "exec ${pkgs.fuzzel}/bin/fuzzel";
        "${modifier}+m" = "workspace mail";
        "${modifier}+Ctrl+q" = "exec ${lock_command}";
        /* Renaming script */
        "${modifier}+Ctrl+r" = "exec ${pkgs.sway-rename-workspace}/bin/sway-rename-workspace";
        /* Custom workspace switching */
        "${modifier}+z" = "workspace prev";
        "${modifier}+x" = "workspace next";
        "${modifier}+grave" = "workspace back_and_forth";
        /* TODO: make this part laptop-specific */
        /*Brightness down */
        "XF86MonBrightnessDown" = "exec '${pkgs.brightnessctl}/bin/brightnessctl set 10%-'";
        "F7" = "exec '${pkgs.brightnessctl}/bin/brightnessctl set 10%-'";
        # Brightness up
        "XF86MonBrightnessUp" = "exec '${pkgs.brightnessctl}/bin/brightnessctl set +10%'";
        "F8" = "exec '${pkgs.brightnessctl}/bin/brightnessctl set +10%'";
      };
      modifier = my_modifier;
      seat = { "*" = { hide_cursor = "when-typing enable"; } ; };
      /* startup = []; # TODO: maybe xremap here? */
      terminal = "${pkgs.kitty}/bin/kitty";
      # Default commands to execute
      window.commands = [
        { command = "kill"; criteria = { class = "Steam"; title = "Steam - News.*"; }; }
      ];
      workspaceAutoBackAndForth = true;
      # swaynag.enable = true;  # Available only on unstable as of Apr 3 2022
    };
    wrapperFeatures = { gtk = true; };
    extraConfig = ''
      for_window [class="Firefox"] inhibit_idle fullscreen
      for_window [class="Brave-browser"] inhibit_idle fullscreen
    '';
  };
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      # target = "sway-session.target"; # Available only on unstable as of Apr 3 2022
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
  };  # TODO: available only on unstable as of Apr 3 2022
  */
  home.packages = with pkgs; [
    wl-clipboard
    mako
    kitty
    dmenu
    fuzzel
# waybar
  ];
}

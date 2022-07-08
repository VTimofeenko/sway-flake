{ pkgs, lib, config, ... }:

let
  cfg = config.vt-sway;
  inherit (config.vt-sway) customTarget;

  set_gsettings = pkgs.writeShellScript "set_gsettings" ''
    PATH=${pkgs.glib}/bin:$PATH

    config="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
    if [ ! -f "$config" ]; then exit 1; fi

    gnome_schema="org.gnome.desktop.interface"
    gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
    font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
    gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
    gsettings set "$gnome_schema" icon-theme "$icon_theme"
    gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
    gsettings set "$gnome_schema" font-name "$font_name"
  '';

  # Color-aware wrapper around the sway-rename-workspace
  sway-rename-workspace-wrapped = pkgs.writeShellScript "sway-rename-workspace-wrapped" ''
    export TITLE_FOREGROUND_COLOR="#${cfg.semanticColors.defaultBg}"
    export TITLE_BACKGROUND_COLOR="#${cfg.semanticColors.otherSelector}"
    export HIGHLIGHTED_FOREGROUND_COLOR="#${cfg.semanticColors.otherSelector}"
    ${pkgs.sway-rename-workspace}/bin/sway-rename-workspace
  '';
in
{
  imports = [
    ./lock.nix
    ./modes.nix
    ./colors.nix
  ];
  # These options are taken from https://nix-community.github.io/home-manager/options.html
  wayland.windowManager.sway = {
    enable = true;
    # Assign windows to workspaces
    config = {
      bars = [ ]; # Set to empty to disable the default. Waybar is managed separately.
      # Criteria for floating windows
      floating.criteria = [
        { class = "^Thunderbird$"; title = ".* Reminder.*"; }
        { class = "Pavucontrol"; }
        { class = "Steam"; title = "Friends List"; }
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
      output = {
        "eDP-1" = { "scale" = "1"; };
      };
      # Custom keybindings
      keybindings =
        let
          inherit (config.wayland.windowManager.sway.config) modifier terminal;
          # Function to make multiple mapping for the same thing
          # Produces an attrset that can be merged with the keybindings attrset
          multiMap = mapping: key_list: builtins.listToAttrs (map (_: { name = _; value = mapping; }) key_list);
        in
        lib.mkOptionDefault
          ({
            /* Launcher */
            "${modifier}+r" = "exec ${pkgs.fuzzel}/bin/fuzzel";
            /* Renaming script */
            "${modifier}+Ctrl+r" = "exec ${sway-rename-workspace-wrapped}";
            /* Custom workspace switching */
            "${modifier}+z" = "workspace prev";
            "${modifier}+x" = "workspace next";
            "${modifier}+grave" = "workspace back_and_forth";
            # Scratchpad terminal shortcut
            "${modifier}+Shift+Return" = ''exec --no-startup-id ${pkgs.scratchpad-terminal}/bin/scratchpad-terminal ${terminal} "scratchpad_term"'';
            "${modifier}+Shift+f" = "floating toggle";
            # Launch something in (t)erminal
            "${modifier}+t" = "exec --no-startup-id ${pkgs.bemenu}/bin/bemenu-run --fork --no-exec | xargs ${terminal}";
          }
          /* Brightnessctl should be called for both F7-8 and fn-F7-8 */
          // multiMap "exec '${pkgs.brightnessctl}/bin/brightnessctl set 10%-'" [ "F7" "XF86MonBrightnessDown" ]
          // multiMap "exec '${pkgs.brightnessctl}/bin/brightnessctl set +10%'" [ "F8" "XF86MonBrightnessUp" ]
          /* Add lower/raise volume mappings */
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%" [ "XF86AudioLowerVolume" ]
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%" [ "XF86AudioRaiseVolume" ]
          );
      seat = { "*" = { hide_cursor = "when-typing enable"; }; };
      startup = [
        /* Stop the graphical-session first if it is running.
          It will be restarted by subsequent start of sway-session.target. */
        { command = "systemctl --user start ${customTarget.fullname}"; }
        { command = "systemctl restart xremap.service"; }
        { command = "${set_gsettings}"; }
        {
          command = "swaybg --image /run/current-system/sw/share/backgrounds/sway/Sway_Wallpaper_Blue_768x1024.png --mode fill";
        }
      ];
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
      for_window [app_id="yad"] floating enable, border none
      no_focus [app_id="yad"]
    '' + ''
      for_window [title="scratchpad_term"] floating enable, move scratchpad
    '';
  };
  home.packages = with pkgs; [
    wl-clipboard
    kitty
    dmenu
    fuzzel
    swaybg
  ];
}

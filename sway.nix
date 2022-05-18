/*
  The first line is written this way to be able to explicitly associate "inputs" with the _flake_'s inputs.
  Otherwise when using this module in the system configuration - system configuration tries to provide the inputs and an error is thrown about missing parameters.'
*/
inputs: { pkgs, lib, ... }:

let
  custom_target = rec {
    name = "sway-wm";
    fullname = name + ".target";
    desc = "Target to bind user-services to.";
  };

  # -f: daemonize
  # -F: show failed attempts
  # -k: show keyboard layout
  # -c: color
  lock_command = "${pkgs.swaylock}/bin/swaylock -fF -k -c 000000";
  my_modifier = "Mod4";
  /* This bit of black magic uses 'mkSchemeAttrs' function from base16 while ensuring that proper pkgs and lib are inherited. With the way 'inputs' are being used (see comment at the beginning) this allows to control which parameter is used from flake, which – from the rest of configuration.
  */
  scheme = (inputs.base16.outputs.lib { inherit pkgs lib; }).mkSchemeAttrs "${inputs.base16-atlas-scheme}/atlas.yaml";
  my_terminal = "${pkgs.kitty}/bin/kitty";
  inherit inputs;
  set_gsettings = pkgs.writeShellScript "set_gsettings" ''
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

  normal_mode_cmd = "exec pkill yad; mode default";
  # The function to create help for mode
  mkHelpNotificationText = mode_def: lib.concatStringsSep "\\n" (lib.mapAttrsToList (name: value: "${name}: ${value}") (lib.filterAttrs (name: value: value != normal_mode_cmd) mode_def.mode."${mode_def.name}"));
  exit_ctl = {
    name = "exit_ctl";
    mode = {
      exit_ctl = {
        "l" = "exec systemctl --user stop ${custom_target.fullname};exec swaymsg exit";
        "s" = "exec systemctl suspend";
        "Shift+s" = "exec systemctl shutdown";
        "Shift+r" = "exec systemctl reboot";
        "Return" = normal_mode_cmd;
        "Escape" = normal_mode_cmd;
      };
    };
  };
in
{
  # inherit test;
  imports = [
    (
      import ./modules/waybar.nix
        ({
          inherit (inputs) base16 base16-atlas-scheme base16-waybar; inherit scheme;
        })
        custom_target
    )
    (
      /* This is a way to pull arguments through when importing a module. Logic is similar to the comments above */
      import ./modules/mako.nix ({ inherit (inputs) base16 base16-atlas-scheme base16-mako; }) custom_target
    )
    ./modules/gtk.nix
  ];
  # These options are taken from https://nix-community.github.io/home-manager/options.html
  wayland.windowManager.sway = {
    enable = true;
    # Assign windows to workspaces
    config = {
      assigns = {
        "mail" = [{ class = "^Thunderbird$"; }];
      };
      bars = [ ]; # Set to empty to disable the default. Waybar is managed separately.
      /* # bindkeysToCode = true; # TODO */
      /* colors = {};  # TODO */
      /* colors = { */
      /*   focused = { */
      /*     background = "#5f676a"; */
      /*     border = vt-colors.colors_named.primary_selection; */
      /*     childBorder = vt-colors.colors_named.primary_selection; */
      /*     indicator = vt-colors.colors_raw.light-purple; */
      /*     text = "#ffffff"; */
      /*   }; */
      /* }; */
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
      # TODO: laptop-specific
      output = {
        "eDP-1" = { "scale" = "1"; };
      };
      modes = lib.mkOptionDefault
        ({
          resize = {
            "Shift+h" = "resize shrink width 100 px";
            "Shift+j" = "resize grow height 100 px";
            "Shift+k" = "resize shrink height 100 px";
            "Shift+l" = "resize grow width 100 px";
          };
        } // exit_ctl.mode);
      # Custom keybindings
      keybindings =
        let
          modifier = my_modifier;
          # Function to make multiple mapping for the same thing
          # Produces an attrset that can be merged with the keybindings attrset
          multiMap = mapping: key_list: builtins.listToAttrs (map (_: { name = _; value = mapping; }) key_list);
        in
        lib.mkOptionDefault
          ({
            /* Launcher */
            "${modifier}+r" = "exec ${pkgs.fuzzel}/bin/fuzzel";
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
            "${modifier}+shift+p" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'systemctl --user stop ${custom_target.fullname} && swaymsg exit'";
            # Scratchpad terminal shortcut
            "${modifier}+Shift+Return" = ''exec --no-startup-id ${pkgs.scratchpad_terminal}/bin/scratchpad_terminal ${my_terminal} "scratchpad_term"'';
            "${modifier}+Shift+f" = "floating toggle";
            "${modifier}+Shift+r" = "mode resize";
            "${modifier}+backslash" = let message = mkHelpNotificationText exit_ctl; in ''exec logger ${message}; exec --no-startup-id ${pkgs.yad}/bin/yad --html --no-buttons --text "${message} --no-focus"; mode ${exit_ctl.name}'';
          }
          /* Add lower/raise volume mappings */
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%" [ "F2" "XF86AudioLowerVolume" ]
          // multiMap "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%" [ "F3" "XF86AudioRaiseVolume" ]
          );
      modifier = my_modifier;
      seat = { "*" = { hide_cursor = "when-typing enable"; }; };
      startup = [
        /* Stop the graphical-session first if it is running.
          It will be restarted by subsequent start of sway-session.target. */
        { command = "systemctl --user start ${custom_target.fullname}"; }
        { command = "systemctl restart xremap.service"; }
        { command = "${set_gsettings}"; }
        {
          command = "swaybg --image /run/current-system/sw/share/backgrounds/sway/Sway_Wallpaper_Blue_768x1024.png --mode fill";
        }
      ];
      terminal = "${my_terminal}";
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
      for_window [app_id="yad"] floating enable
    '' + (with scheme; ''
      client.focused          ${base05} ${base0D} ${base00} ${base0D} ${base0D}
      client.focused_inactive ${base01} ${base01} ${base05} ${base03} ${base01}
      client.unfocused        ${base01} ${base00} ${base05} ${base01} ${base01}
      client.urgent           ${base08} ${base08} ${base00} ${base08} ${base08}
      client.placeholder      ${base00} ${base00} ${base05} ${base00} ${base00}
      client.background       ${base07}
    '') + ''
      for_window [title="scratchpad_term"] floating enable, move scratchpad
    '';
  };
  systemd.user.services = {
    swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        Documentation = [ "man:swayidle(1)" ];
        PartOf = [ "${custom_target.fullname}" ];
        BindsTo = [ "${custom_target.fullname}" ];
      };
      Install = {
        WantedBy = [ "${custom_target.fullname}" ];
      };
      Service = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 600 '${lock_command}' \
            timeout 600 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            before-sleep '${lock_command}'
        '';
      };
    };
  };
  # custom target to bind services to
  systemd.user.targets."${custom_target.name}" = {
    Unit = {
      Description = custom_target.desc;
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
    kitty
    dmenu
    fuzzel
    swaybg
  ];
}

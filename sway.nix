/*
The first line is written this way to be able to explicitly associate "inputs" with the _flake_'s inputs.
Otherwise when using this module in the system configuration - system configuration tries to provide the inputs and an error is thrown about missing parameters.'
*/
inputs: { pkgs, lib, ... }:

let
  # -f: daemonize
  # -F: show failed attempts
  # -k: show keyboard layout
  # -c: color
  lock_command = "${pkgs.swaylock}/bin/swaylock -fF -k -c 000000";
  my_modifier = "Mod4";
  /* This bit of black magic uses 'mkSchemeAttrs' function from base16 while ensuring that proper pkgs and lib are inherited. With the way 'inputs' are being used (see comment at the beginning) this allows to control which parameter is used from flake, which – from the rest of configuration.
  */
  scheme = (inputs.base16.outputs.lib {inherit pkgs lib;}).mkSchemeAttrs "${inputs.base16-atlas-scheme}/atlas.yaml";
  inherit inputs;
in
{
  # inherit test;
  imports = [
    (
     import ./modules/waybar.nix ( { inherit (inputs) base16 base16-atlas-scheme base16-waybar; inherit scheme; })
    )
    (
      /* This is a way to pull arguments through when importing a module. Logic is similar to the comments above */
      import ./modules/mako.nix ( { inherit (inputs) base16 base16-atlas-scheme base16-mako; })
    )
  ];
  # These options are taken from https://nix-community.github.io/home-manager/options.html
  wayland.windowManager.sway = {
    enable = true;
    # Assign windows to workspaces
    config = {
      assigns = {
        "mail" = [{ class = "^Thunderbird$"; }];
      };
      bars = [];  # Set to empty to disable the default. Waybar is managed separately.
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
      # TODO: laptop-specific
      output = {
        "eDP-1"= { "scale" = "1"; };
      };
      modes = lib.mkOptionDefault {
        resize = {
          "Shift+h" = "resize shrink width 100 px";
          "Shift+j" = "resize grow height 100 px";
          "Shift+k" = "resize shrink height 100 px";
          "Shift+l" = "resize grow width 100 px";
        };

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
        "${modifier}+shift+p" = "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'systemctl --user stop graphical-session.target app.slice && swaymsg exit'";
      };
      modifier = my_modifier;
      seat = { "*" = { hide_cursor = "when-typing enable"; } ; };
      startup = [
        /* Stop the graphical-session first if it is running.
        It will be restarted by subsequent start of sway-session.target. */
        { command = "systemctl --user stop sway-session.target"; }
        { command = "systemctl restart xremap.service"; }
        # { command = "mako"; }
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
      '' + (with scheme; ''
      client.focused          ${base05} ${base0D} ${base00} ${base0D} ${base0D}
      client.focused_inactive ${base01} ${base01} ${base05} ${base03} ${base01}
      client.unfocused        ${base01} ${base00} ${base05} ${base01} ${base01}
      client.urgent           ${base08} ${base08} ${base00} ${base08} ${base08}
      client.placeholder      ${base00} ${base00} ${base05} ${base00} ${base00}
      client.background       ${base07}
    '');
  };
  systemd.user.services = {
    swayidle = {
      Unit = {
        Description = "Idle manager for Wayland";
        Documentation = [ "man:swayidle(1)" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart=''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 600 '${lock_command}' \
            timeout 600 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            before-sleep '${lock_command}'
          '';
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
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
  };  # TODO: available only on unstable as of Apr 3 2022
  */
  home.packages = with pkgs; [
    wl-clipboard
    mako
    kitty
    dmenu
    fuzzel
  ];
}

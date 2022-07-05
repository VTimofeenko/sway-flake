waybarTemplate: { pkgs, config, ... }:

let
  inherit (config.vt-sway) customTarget;
  /* Function that turns an icon into a <span> to force a specific font */
  mkSpan = icon: "<span font=\"Font Awesome 5 Free Solid\">${icon}</span>";
  start-waybar = pkgs.writeShellScriptBin "start-waybar" ''
    export SWAYSOCK=/run/user/$(id -u)/sway-ipc.$(id -u).$(pgrep -f 'sway$').sock
    ${pkgs.waybar}/bin/waybar
  '';
in
{
  systemd.user.services.waybar = {
    Service = {
      ExecStart = pkgs.lib.mkForce "${start-waybar}/bin/start-waybar";
    };
    Unit = {
      BindsTo = [ "${customTarget.fullname}" ];
      PartOf = [ "${customTarget.fullname}" ];
      # Set to 2 to limit race when logging out
      StartLimitBurst = 2;
    };
    Install = {
      WantedBy = [ "${customTarget.fullname}" ];
    };
  };
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      /* # target = "sway-session.target"; # Available only on unstable as of Apr 3 2022 */
    };
    settings = [{
      /* Waybar config. */
      /* Default is here: https://github.com/Alexays/Waybar/blob/master/resources/config */
      layer = "bottom";
      position = "top";
      height = 30;
      /* output = [ "eDP-1" ]; */
      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ ];
      modules-right = [ "tray" "idle_inhibitor" "pulseaudio" "network" "temperature" "cpu" "sway/language" "battery" "clock" ];

      modules = {
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
        "clock" = {
          /* "-d" removes leading zero */
          "format" = "{:%b %-d %R}";
          "tooltip" = false;
        };
        "sway/mode" = {
          "format" = "<span style=\"italic\">{}</span>";
        };
        "idle_inhibitor" = {
          "format" = "{icon}";
          "format-icons" = {
            "activated" = mkSpan "";
            "deactivated" = mkSpan "";
          };
        };
        "temperature" = {
          "thermal-zone" = 3;
          "critical-threshold" = 80;
          "format-critical" = mkSpan "{icon}" + " {temperatureC}°C";
          "format" = mkSpan "{icon}" + " {temperatureC}°C";
          "format-icons" = [ "" "" "" ];
        };
        "cpu" = {
          "format" = mkSpan "" + " {usage}%";
          "tooltip" = false;
        };
        "battery" = {
          "states" = {
            "good" = 95;
            "warning" = 30;
            "critical" = 15;
          };
          "format" = mkSpan "{icon}" + " {capacity}%";
          "format-charging" = mkSpan "{icon}" + " {capacity}% " + mkSpan "";
          "format-plugged" = mkSpan "{icon}" + " {capacity}% " + mkSpan "";
          "format-alt" = "{time} " + mkSpan "{icon}";
          "format-icons" = [ "" "" "" "" "" ];
        };
        "network" = {
          "format-wifi" = mkSpan " " + " {essid}";
          "format-ethernet" = mkSpan "" + " {ipaddr}";
          "tooltip-format" = "{ifname} via {gwaddr} ";
          "format-linked" = "{ifname} (No IP)";
          "format-disconnected" = mkSpan "⚠" + " Disconnected";
        };
        "pulseaudio" = {
          "format" = mkSpan "{icon}" + " {volume}%";
          "format-bluetooth" = "{volume}% {icon} {format_source}";
          "format-bluetooth-muted" = " {icon} {format_source}";
          "format-muted" = "";
          "format-source" = "";
          "format-source-muted" = "";
          "format-icons" = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [ "" "" "" ];
          };
          "on-click" = "pavucontrol";
        };
      };
    }];
    style = ''
      ${builtins.readFile waybarTemplate}
      ${builtins.readFile ./waybar.style.css}
    '';
  };
}

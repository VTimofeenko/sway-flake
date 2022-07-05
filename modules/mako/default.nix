makoTemplate: { pkgs, config, ... }:
let
  inherit (config.vt-sway) customTarget;
in
{
  programs.mako = {
    enable = true;
    defaultTimeout = 5000;
    extraConfig = builtins.readFile (makoTemplate);
  };
  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "${customTarget.fullname}" ];
      BindsTo = [ "${customTarget.fullname}" ];
    };
    Install = {
      WantedBy = [ "${customTarget.fullname}" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.mako}/bin/mako";
      RestartSec = 5;
      Restart = "always";
    };
  };
}

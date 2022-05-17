inputs: custom_target: { pkgs, lib, ... }:

let
  template = (inputs.base16.outputs.lib { inherit pkgs lib; }).mkSchemeAttrs
    # The color scheme
    "${inputs.base16-atlas-scheme}/atlas.yaml"
    # The template
    inputs.base16-mako;
in
{
  programs.mako = {
    enable = true;
    defaultTimeout = 5000;
    # backgroundColor = vt-colors.colors_raw.light-purple;
    extraConfig = builtins.readFile (template);
  };
  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      PartOf = [ "${custom_target.fullname}" ];
      BindsTo = [ "${custom_target.fullname}" ];
    };
    Install = {
      WantedBy = [ "${custom_target.fullname}" ];
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

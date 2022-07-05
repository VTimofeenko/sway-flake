{ pkgs, lib, config, ... }:
let
  inherit (config.vt-sway) semanticColors customTarget;
  # I don't need the tray service, rather start it on-demand
  settings = {
    General = {
      # A share of purple I like slightly more
      uiColor = "#${semanticColors.otherSelector}";
      showHelp = false;
    };
  };

  iniFormat = pkgs.formats.ini { };

  iniFile = iniFormat.generate "flameshot.ini" settings;
in
{
  services.flameshot = {
    enable = true;
    inherit settings;
  };
  systemd.user.services.flameshot = {
    Unit = {
      Requires = [ "${customTarget.fullname}" "xdg-desktop-portal.service" ];
      After = [ "${customTarget.fullname}" "xdg-desktop-portal.service" ];
    };
  };
  /* xdg.configFile."flameshot/flameshot.ini".source = iniFile; */
  /* wayland.windowManager.sway.config = { */
  /*   keybindings = lib.mkOptionDefault ( */
  /*     let */
  /*       modifier = config.wayland.windowManager.sway.config.modifier; */
  /*     in */
  /*     { */
  /*       "${modifier}+Ctrl+s" = "${pkgs.flameshot} gui"; */
  /*     } */
  /*   ); */
  /* }; */
}

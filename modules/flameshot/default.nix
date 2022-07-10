{ pkgs, lib, config, ... }:
let
  inherit (config.vt-sway) semanticColors customTarget;
  # I don't need the tray service, rather start it on-demand
  settings = {
    General = {
      # A share of purple I like slightly more
      uiColor = "#${semanticColors.otherSelector}";
      showHelp = false;
      checkForUpdates = false;
      showStartupLaunchMessage = false;
      buttons = ''@Variant(\0\0\0\x7f\0\0\0\vQList<int>\0\0\0\0\x11\0\0\0\0\0\0\0\x1\0\0\0\x2\0\0\0\x3\0\0\0\x4\0\0\0\x5\0\0\0\x6\0\0\0\x12\0\0\0\x13\0\0\0\a\0\0\0\b\0\0\0\t\0\0\0\x10\0\0\0\n\0\0\0\v\0\0\0\x17\0\0\0\f)'';
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

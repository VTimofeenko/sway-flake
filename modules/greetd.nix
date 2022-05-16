{ pkgs, lib, ... }:

let
  sway-launcher = pkgs.writeShellScript "sway-launcher" ''
    exec systemd-cat --identifier=sway sway
  '';
in
{
  # Enable greeter
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # taken from https://github.com/apognu/tuigreet
        command = "${lib.makeBinPath [pkgs.greetd.tuigreet] }/tuigreet --time --cmd ${sway-launcher}";
        id = "greeter";
      };
    };
  };
}

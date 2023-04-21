{ pkgs, lib, ... }:

let
  inherit (import ./sway-with-patches.nix pkgs) patched-sway;


  sway-launcher = pkgs.writeShellScript "sway-launcher" ''
    exec systemd-cat --identifier=sway ${patched-sway}/bin/sway
    systemctl --user stop sway-wm.target
  '';
in
{
  # Enable greeter
  boot.kernelParams = [ "console=tty1" ];
  services.greetd = {
    vt = 2;
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

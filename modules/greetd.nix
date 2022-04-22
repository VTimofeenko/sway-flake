{ pkgs, lib, ... }:

{
  # Enable greeter
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # taken from https://github.com/apognu/tuigreet
        command = "${lib.makeBinPath [pkgs.greetd.tuigreet] }/tuigreet --time --cmd sway";
        id = "greeter";
      };
    };
  };
}

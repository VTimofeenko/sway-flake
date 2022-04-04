# This module contains system-wide settings for this flake
{ pkgs, ... }:

{
  # Swaylock requires this
  # TODO: maybe not needed
  security.pam.services.swaylock = {
    text = "auth include login";
  };
  # According to https://blog.patapon.info/nixos-systemd-sway/ this restores a bunch of stuff
  programs.sway.enable = true;
  programs.dconf.enable = true;
}

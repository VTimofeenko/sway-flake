# This module contains system-wide settings for this flake
{ pkgs, ... }:

{
  # Swaylock requires this
  security.pam.services.swaylock = {
    text = "auth include login";
  };
}

# This module contains system-wide settings for this flake
{ pkgs, ... }:

{
  imports = [
    ./greetd.nix
    ./additional-packages.nix
  ];
  # According to https://blog.patapon.info/nixos-systemd-sway/ this restores a bunch of stuff
  programs.sway.enable = true;
  programs.dconf.enable = true;
  hardware.opengl.enable = true;

  # Needed for flameshot
  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  # fonts

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      roboto
      twitter-color-emoji
      font-awesome
    ];
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "Roboto" ];
        serif = [ "Roboto" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
  };
}

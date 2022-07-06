{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    xdg-utils # Needed for kitty URL opener
  ];
}

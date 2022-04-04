{ vt-colors, ... }:

{
  programs.mako = {
    enable = true;
    defaultTimeout = 5000;
    backgroundColor = vt-colors.colors_raw.light-purple;
  };
}

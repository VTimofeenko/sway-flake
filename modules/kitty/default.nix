{ pkgs, config, ... }:
let
in
{
  programs.kitty = {
    enable = true;
    # theme = "Neopolitan";
    theme = "Doom Vibrant";
    settings = {
      cursor_blink_interval = 0;
      background_opacity = "0.95";
      enable_audio_bell = false;
      tab_bar_margin_width = 9;
      tab_bar_margin_height = "2 2";
      tab_bar_style = "separator";
      tab_bar_min_tabs = 1;
      tab_bar_edge = "bottom";
      tab_title_template = "{fmt.fg.white} {title.split()[0]} ";
      active_tab_title_template = "{fmt.fg.black}{fmt.fg.blue} {title.split()[0]} ";
    };
    keybindings = {
      # Opens a new Kitty window in the current working directory
      "kitty_mod+enter" = "launch --cwd=current";
    };
  };
}

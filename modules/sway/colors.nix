# Module that configures colors for sway according to the options
{ config, ... }:
let
  inherit (config.vt-sway) semanticColors;
in
{
  /*
    The general logic for sway colorschemes:
    client.<class> <border> <background> <text> [<indicator> [<child_border>]]
    Configures the color of window borders and title bars. The first three colors are required. When omitted indicator will use a sane default and child_border will use the color set for background. Colors may be specified in hex, either as #RRGGBB or #RRGGBBAA.

    The available classes are:

    * client.focused — The window that has focus.
    * client.focused_inactive — The most recently focused view within a container which is not focused.
    * client.focused_tab_title — A view that has focused descendant container. Tab or stack container title that is the parent of the focused container but is not directly focused. Defaults to focused_inactive if not specified and does not use the indicator and child_border colors.
    * client.placeholder — Ignored (present for i3 compatibility).
    * client.unfocused — A view that does not have focus.
    * client.urgent — A view with an urgency hint. Note: Native Wayland windows do not support urgency. Urgency only works for Xwayland windows.

    The meaning of each color is:

    * border — The border around the title bar.
    * background — The background of the title bar.
    * text — The text color of the title bar.
    * indicator — The color used to indicate where a new view will open. In a tiled container, this would paint the right border of the current view if a new view would be opened to the right.
    * child_border — The border around the view itself.

  */
  wayland.windowManager.sway.extraConfig = with semanticColors; ''
    # Semantic colors
    client.focused          ${highlight} ${defaultBg} ${defaultFg} ${selector} ${highlight}
    client.focused_inactive ${defaultBg} ${defaultBg} ${defaultFg} ${defaultBg} ${defaultBg}
    client.unfocused        ${defaultBg} ${defaultBg} ${defaultFg} ${defaultBg} ${defaultBg}
    client.urgent           ${alarm} ${alarm} ${defaultFg} ${alarm} ${alarm}
  '';
}
